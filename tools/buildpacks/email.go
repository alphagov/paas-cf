package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"text/template"
	"time"

	"github.com/google/go-github/v21/github"
	"golang.org/x/oauth2"
	yaml "gopkg.in/yaml.v2"
)

type EmailDatas struct {
	ReleaseDate string
	Data        []EmailData
}
type EmailData struct {
	Buildpack           Buildpack
	ReleaseNoteVersions []string
	Changes             map[string]Changes
}

type Changes struct {
	Additions []string
	Removals  []string
}

func toSet(input []string) map[string]bool {
	set := map[string]bool{}
	for _, item := range input {
		set[item] = true
	}
	return set
}

func difference(as, bs []string) (differences []string) {
	asSet := toSet(as)
	bsSet := toSet(bs)
	for aKey := range asSet {
		if _, ok := bsSet[aKey]; !ok {
			differences = append(differences, aKey)
		}
	}
	return differences
}

func dependencyVersionsByName(dependencies []Dependency) (dependencyVersionsByName map[string][]string) {
	dependencyVersionsByName = map[string][]string{}
	for _, dependency := range dependencies {
		dependencyVersionsByName[dependency.Name] = append(dependencyVersionsByName[dependency.Name], dependency.Version)
	}
	return dependencyVersionsByName
}

func releasesSinceLastRelease(ctx context.Context, githubClient *github.Client, repoName string, lastRelease string) (releaseVersions []string) {

	releases, _, err := githubClient.Repositories.ListReleases(
		ctx,
		"cloudfoundry",
		repoName,
		&github.ListOptions{
			PerPage: 100,
		})
	if err != nil {
		log.Fatalf("Failed to get repository %s from github %v", repoName, err)
	}

	for _, release := range releases {
		releaseVersions = append(releaseVersions, release.GetTagName())
		if release.GetTagName() == lastRelease {
			break
		}
	}

	return releaseVersions
}

func main() {
	var (
		oldFilePath        = flag.String("old", "", "Old file")
		newFilePath        = flag.String("new", "", "New file")
		markdownOutputPath = flag.String("markdownout", "", "Path to output markdown file to")
	)
	flag.Parse()

	if *oldFilePath == "" {
		flag.Usage()
		log.Fatal("old must be set")
	}
	if *newFilePath == "" {
		flag.Usage()
		log.Fatal("new must be set")
	}
	if *markdownOutputPath == "" {
		flag.Usage()
		log.Fatal("markdownout must be set")
	}

	oldFileData, err := ioutil.ReadFile(*oldFilePath)
	if err != nil {
		log.Fatalf("oldFileData cannot be read from %s: %v", *oldFilePath, err)
	}
	newFileData, err := ioutil.ReadFile(*newFilePath)
	if err != nil {
		log.Fatalf("newFileData cannot be read from %s: %v", *newFilePath, err)
	}
	ctx := context.Background()
	githubToken, ok := os.LookupEnv("GITHUB_API_TOKEN")
	if !ok {
		log.Fatalf("environment variable GITHUB_API_TOKEN must be set")
	}
	ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: githubToken})
	tc := oauth2.NewClient(ctx, ts)
	githubClient := github.NewClient(tc)
	oldBuildpacks := Buildpacks{}
	err = yaml.Unmarshal(oldFileData, &oldBuildpacks)

	newBuildpacks := Buildpacks{}
	err = yaml.Unmarshal(newFileData, &newBuildpacks)

	emailData := EmailDatas{
		Data:        []EmailData{},
		ReleaseDate: time.Now().AddDate(0, 0, 7).Format("2006-01-02"),
	}
	doneBuildpacks := map[string]bool{}
	for idx, newBuildpack := range newBuildpacks.Buildpacks {
		if doneBuildpacks[newBuildpack.Name] {
			continue
		}
		oldBuildpack := oldBuildpacks.Buildpacks[idx]

		releaseNoteVersions := releasesSinceLastRelease(ctx, githubClient, newBuildpack.RepoName, oldBuildpack.Version)
		buildpackEmailData := EmailData{
			Buildpack:           newBuildpack,
			ReleaseNoteVersions: releaseNoteVersions,
			Changes:             make(map[string]Changes),
		}

		oldDependenciesByName := dependencyVersionsByName(oldBuildpack.Dependencies)
		newDependenciesByName := dependencyVersionsByName(newBuildpack.Dependencies)
		additionsByName := map[string][]string{}
		removalsByName := map[string][]string{}
		for name, versions := range oldDependenciesByName {
			var tmpChanges = buildpackEmailData.Changes[name]
			removals := difference(versions, newDependenciesByName[name])
			removalsByName[name] = removals
			tmpChanges.Removals = removals
			if len(removals) > 0 {
				buildpackEmailData.Changes[name] = tmpChanges
			}
		}
		for name, versions := range newDependenciesByName {
			var tmpChanges = buildpackEmailData.Changes[name]
			additions := difference(versions, oldDependenciesByName[name])
			additionsByName[name] = additions
			tmpChanges.Additions = additions
			if len(additions) > 0 {
				buildpackEmailData.Changes[name] = tmpChanges
			}
		}
		emailData.Data = append(emailData.Data, buildpackEmailData)
		doneBuildpacks[newBuildpack.Name] = true
	}
	// asYAML, _ := yaml.Marshal(emailData)
	// fmt.Print(string(asYAML))
	tmpl, err := template.ParseFiles("email.tmpl", "markdown.tmpl")
	if err != nil {
		log.Fatalf("Email template could not be loaded %v", err)
	}
	var emailText bytes.Buffer
	err = tmpl.ExecuteTemplate(&emailText, "email.tmpl", emailData)
	if err != nil {
		log.Fatalf("Email template could not be executed %v", err)
	}
	var markdownText bytes.Buffer
	err = tmpl.ExecuteTemplate(&markdownText, "markdown.tmpl", emailData)
	if err != nil {
		log.Fatalf("Markdown template could not be executed %v", err)
	}
	ioutil.WriteFile(*markdownOutputPath, markdownText.Bytes(), 0644)
	fmt.Print(string(emailText.Bytes()))
}
