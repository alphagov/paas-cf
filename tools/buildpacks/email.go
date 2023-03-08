package main

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"text/template"
	"time"

	"github.com/gomarkdown/markdown"
	"github.com/google/go-github/v24/github"
	"golang.org/x/mod/semver"
	"golang.org/x/oauth2"
	yaml "gopkg.in/yaml.v2"
)

var endOfHighlightMarker = "<!-- ------------------------ >8 ------------------------ -->"

type EmailDatas struct {
	ReleaseDate string
	Data        []EmailData
}

func (ed EmailDatas) HasAnyHighlights() bool {
	for _, d := range ed.Data {
		if d.HasHighlights {
			return true
		}
	}

	return false
}

type EmailData struct {
	Buildpack           Buildpack
	ReleaseNoteVersions []string
	Changes             map[string]Changes
	Highlights          string
	HasHighlights       bool
}

type Changes struct {
	Additions []string
	Removals  []string
}

type ReleaseNotes struct {
	Version string
	Body    string
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
	// sort the versions of each dependency newest to oldest
	for dependency, _ := range dependencyVersionsByName {
		semver.Sort(dependencyVersionsByName[dependency])
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
		if release.GetTagName() == lastRelease {
			break
		}
		releaseVersions = append(releaseVersions, release.GetTagName())
	}

	return releaseVersions
}

// Compiles the release notes for a buildpack.
// Starts at the given version and runs up until the latest version.
// Returns a slice of ReleaseNotes structs because ordering is important.
func getCompiledReleaseNotes(ctx context.Context, githubClient *github.Client, repoName string, lastRelease string) ([]ReleaseNotes, error) {
	var compiled []ReleaseNotes

	releases, _, err := githubClient.Repositories.ListReleases(
		ctx,
		"cloudfoundry",
		repoName,
		&github.ListOptions{
			PerPage: 100,
		})
	if err != nil {
		return nil, err
	}

	for _, release := range releases {
		if release.GetTagName() == lastRelease {
			break
		}

		compiled = append(compiled, ReleaseNotes{
			Version: release.GetTagName(),
			Body:    release.GetBody(),
		})
	}
	return compiled, nil
}

func getUserInputFromEditor(promptString string) (string, error) {
	pwd, err := os.Getwd()
	if err != nil {
		return "", err
	}

	tempFile, err := ioutil.TempFile(pwd, ".tmp-buildpack-highlight-*.md")
	if err != nil {
		return "", err
	}
	defer os.Remove(tempFile.Name())

	err = ioutil.WriteFile(tempFile.Name(), []byte(promptString), 0750)
	if err != nil {
		return "", err
	}

	editorName, editorIsSet := os.LookupEnv("EDITOR")
	if !editorIsSet {
		editorName = "vim"
	}
	editorArgs := []string{}
	// sometimes, EDITOR is set to a command with arguments
	if regexp.MustCompile(`\s`).MatchString(editorName) {
		editorArgs = strings.Split(editorName, " ")
		editorName = editorArgs[0]
		editorArgs = editorArgs[1:]
	}
	editorArgs = append(editorArgs, tempFile.Name())

	var content []byte
	for {
		editor := exec.Command(editorName, editorArgs...)
		editor.Stdin = os.Stdin
		editor.Stdout = os.Stdout
		editor.Stderr = os.Stderr
		editor.Env = os.Environ()
		editor.Dir = pwd

		err = editor.Start()
		if err != nil {
			return "", err
		}

		err = editor.Wait()
		if err != nil {
			return "", err
		}

		content, err = ioutil.ReadFile(tempFile.Name())
		if err != nil {
			return "", err
		}

		if checkInputHasMarkerLine(string(content)) {
			break
		}
		log.Printf("Please add the following marker to the end of your highlights:\n%s", endOfHighlightMarker)
		log.Printf("Press enter to continue")
		fmt.Scanln()

	}
	return string(content), err
}

func main() {
	var (
		oldFilePath    = flag.String("old", "", "Old file")
		newFilePath    = flag.String("new", "", "New file")
		outputFile     = flag.String("out", "", "Output file")
		outputHtmlFile = flag.String("htmlout", "", "Output html file")
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

	oldFileData, err := ioutil.ReadFile(*oldFilePath)
	if err != nil {
		log.Fatalf("oldFileData cannot be read from %s: %v", *oldFilePath, err)
	}
	newFileData, err := ioutil.ReadFile(*newFilePath)
	if err != nil {
		log.Fatalf("newFileData cannot be read from %s: %v", *newFilePath, err)
	}
	dependenciesToHighlightFileData, err := ioutil.ReadFile("dependencies_to_highlight.yaml")
	if err != nil {
		log.Fatalf("dependencyToHighlightFileData cannot be read from dependencies_to_highlight.yaml: %v", err)
	}
	ctx := context.Background()
	var githubClient *github.Client
	githubTokenPossibleEnvars := []string{"GITHUB_TOKEN", "GITHUB_API_TOKEN"}
	var githubToken string
	var ok bool
	// set githubToken to the first environment variable that is set
	for _, envvar := range githubTokenPossibleEnvars {
		githubToken, ok = os.LookupEnv(envvar)
		if ok {
			break
		}
	}
	if !ok {
		log.Printf("GitHub token not found in environment. If GitHub communication errors are seen, you may need to export a token with 'public_repo' access")
		log.Printf("Checked environment variables: %s", strings.Join(githubTokenPossibleEnvars, ", "))
		githubClient = github.NewClient(nil)
	} else {
		ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: githubToken})
		tc := oauth2.NewClient(ctx, ts)
		githubClient = github.NewClient(tc)
	}
	oldBuildpacks := Buildpacks{}
	err = yaml.Unmarshal(oldFileData, &oldBuildpacks)
	if err != nil {
		log.Fatalf("oldBuildpacks cannot be unmarshalled: %v", err)
	}

	newBuildpacks := Buildpacks{}
	err = yaml.Unmarshal(newFileData, &newBuildpacks)
	if err != nil {
		log.Fatalf("newBuildpacks cannot be unmarshalled: %v", err)
	}

	dependenciesToHighlight := Buildpacks{}
	err = yaml.Unmarshal(dependenciesToHighlightFileData, &dependenciesToHighlight)
	if err != nil {
		log.Fatalf("dependencyToHighlightFileData cannot be unmarshalled: %v", err)
	}

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
		if len(releaseNoteVersions) == 0 {
			continue
		}
		buildpackEmailData := EmailData{
			Buildpack:           newBuildpack,
			ReleaseNoteVersions: releaseNoteVersions,
			Changes:             make(map[string]Changes),
			Highlights:          "",
			HasHighlights:       false,
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

		compiledReleaseNotes, err := getCompiledReleaseNotes(ctx, githubClient, newBuildpack.RepoName, oldBuildpack.Version)
		if err != nil {
			log.Fatalf("could not get compiled release notes for buildpack '%s': %s", newBuildpack.Name, err)
			return
		}
		prefilledHighlights := getPrefilledHighlights(newBuildpack.Name, dependenciesToHighlight, additionsByName, removalsByName)
		editorInput := commentifyCompiledReleaseNotes(newBuildpack.Name, compiledReleaseNotes, prefilledHighlights)
		highlights, err := getUserInputFromEditor(editorInput)
		if err != nil {
			log.Fatalf("couldn't get highlights for buildpack: %s", err)
			return
		}

		strippedHighlights := stripCommentedLines(highlights)
		if strippedHighlights != "" {
			buildpackEmailData.Highlights = strippedHighlights
			buildpackEmailData.HasHighlights = true
		}

		emailData.Data = append(emailData.Data, buildpackEmailData)
		doneBuildpacks[newBuildpack.Name] = true
	}

	tmpl, err := template.ParseFiles("email.tmpl")
	if err != nil {
		log.Fatalf("Email template could not be loaded %v", err)
	}
	var emailText bytes.Buffer
	err = tmpl.ExecuteTemplate(&emailText, "email.tmpl", emailData)
	if err != nil {
		log.Fatalf("Email template could not be executed %v", err)
	}

	err = ioutil.WriteFile(*outputFile, emailText.Bytes(), 0750)
	if err != nil {
		log.Fatalf("Email template could not be written to file '%s' %v", *outputFile, err)
	}

	if *outputHtmlFile != "" {
		ioutil.WriteFile(*outputHtmlFile, markdown.ToHTML(emailText.Bytes(), nil, nil), 0750)
		if err != nil {
			log.Fatalf("Email template could not be written to file '%s' %v", *outputHtmlFile, err)
		}
	}
}

func getPrefilledHighlights(buildpackName string, dependenciesToHighlight Buildpacks, additionsByName map[string][]string, removalsByName map[string][]string) string {
	var toHighlight = []string{}
	for _, buildpack := range dependenciesToHighlight.Buildpacks {
		if buildpack.Name == buildpackName {
			toHighlight = buildpack.DependenciesToHighlight
			break
		}
	}
	if len(toHighlight) == 0 {
		return ""
	}
	var highlights = ""
	for _, dependency := range toHighlight {
		if additionsByName[dependency] == nil && removalsByName[dependency] == nil {
			continue
		}
		if len(additionsByName[dependency]) > 0 || len(removalsByName[dependency]) > 0 {
			highlights += fmt.Sprint("### Versions\n")
			highlights += fmt.Sprintf("- %s\n", dependency)
		} else {
			continue
		}
		if len(additionsByName[dependency]) > 0 {
			highlights += "  - Added: " + strings.Join(additionsByName[dependency], ", ") + "\n"
		}
		if len(removalsByName[dependency]) > 0 {
			highlights += "  - Removed: " + strings.Join(removalsByName[dependency], ", ") + "\n"
		}
	}
	return highlights
}

// Takes the compiled release notes for a buildpack and prepares them to be
// presented to the user in a way that's similar to the way notes are in "git commit"
func commentifyCompiledReleaseNotes(buildpackName string, releaseNotes []ReleaseNotes, prefilledHighlights string) string {
	builder := strings.Builder{}

	builder.WriteString(prefilledHighlights + "\n\n") // Space for the user to write in
	builder.WriteString(`<!-- ------------------------ >8 ------------------------ -->
> ***Do not modify or remove the line above.***
> Everything below it will be ignored.
>
> Read the release notes below and write up any highlights above.
> Don't include a title line. This will be added when the email is compiled.
>
> Empty highlights will not be included in the email.
`)

	builder.WriteString("## " + buildpackName + "\n\n")
	for _, notes := range releaseNotes {
		builder.WriteString("---\n\n")
		builder.WriteString("### " + notes.Version + "\n")
		builder.WriteString(notes.Body + "\n")
	}

	return builder.String()
}

// Returns the contents of the file, with everything after endOfHighlightMarker removed
func stripCommentedLines(input string) string {
	var out []string
	for _, str := range strings.Split(input, "\n") {
		if str == endOfHighlightMarker {
			break
		}
		out = append(out, str)
	}
	return strings.TrimSpace(strings.Join(out, "\n"))
}

func checkInputHasMarkerLine(input string) bool {
	for _, str := range strings.Split(input, "\n") {
		if str == endOfHighlightMarker {
			return true
		}
	}
	return false
}
