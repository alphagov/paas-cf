package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/google/go-github/v24/github"
	"golang.org/x/oauth2"
	yaml "gopkg.in/yaml.v2"
)

type AssetDetails struct {
	Url      string
	Filename string
	Sha      string
}

type DefaultVersion struct {
	Name    string `yaml:"name"`
	Version string `yaml:"version"`
}

type Manifest struct {
	DefaultVersions []DefaultVersion `yaml:"default_versions"`
	Dependencies    []Dependency     `yaml:"dependencies"`
}

// Adapted from ioutil.WriteFile
func copyToFile(filepath string, source io.Reader) error {
	f, err := os.Create(filepath)
	if err != nil {
		return err
	}
	_, err = io.Copy(f, source)
	if err1 := f.Close(); err == nil {
		err = err1
	}
	return err
}

func downloadFile(filepath string, url string) error {
	// Get the data
	resp, err := http.Get(url)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	// Write the body to file
	err = copyToFile(filepath, resp.Body)
	if err != nil {
		return err
	}

	return nil
}

func getAssetSha(assetDetails AssetDetails) (sha string) {
	tmpDir, err := ioutil.TempDir("/tmp", "create_buildpacks")
	if err != nil {
		log.Fatalf("Temporary download dir could not be created %v", err)
	}
	defer os.RemoveAll(tmpDir)

	downloadFileName := fmt.Sprintf("%s/%s", tmpDir, assetDetails.Filename)
	err = downloadFile(downloadFileName, assetDetails.Url)
	if err != nil {
		log.Fatalf("File %s could not be downloaded to %s %v", assetDetails.Url, downloadFileName, err)
	}
	f, err := os.Open(downloadFileName)
	if err != nil {
		log.Fatalf("File %s could not be opened %v", downloadFile, err)
	}
	defer f.Close()
	hasher := sha256.New()
	if _, err := io.Copy(hasher, f); err != nil {
		log.Fatalf("Calculating SHA256SUM of %s failed %v", downloadFileName, err)
	}
	return hex.EncodeToString(hasher.Sum(nil))
}

func readManifest(ctx context.Context, githubClient *github.Client, buildpack Buildpack, latestRelease *github.RepositoryRelease) (manifest Manifest) {
	fileContent, _, _, err := githubClient.Repositories.GetContents(
		ctx,
		"cloudfoundry",
		buildpack.RepoName,
		"manifest.yml",
		&github.RepositoryContentGetOptions{
			Ref: *latestRelease.TagName,
		},
	)
	if err != nil {
		// log.Fatalf("could not get contents for manifest for %s, %v", buildpack.RepoName, err)
		return manifest
	}
	fileBytes, err := fileContent.GetContent()
	if err != nil {
		log.Fatalf("could not read contents for manifest for %s, %v", buildpack.RepoName, err)
	}
	err = yaml.Unmarshal([]byte(fileBytes), &manifest)
	if err != nil {
		log.Fatalf("could not unmarshal manifest as YAML, %v", err)
	}
	return manifest
}

func downloadSha(url, repoName string) (shasum string) {
	resp, err := http.Get(url)
	if err != nil {
		log.Fatalf("could not download shasum for %s, %v", repoName, err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatalf("could not read response for shasum for %s, %v", repoName, err)
	}
	return strings.Split(string(body), " ")[0]
}

func getAssetDetails(assets []github.ReleaseAsset, repoName, nameFilter string) (assetDetails AssetDetails, ok bool) {
	ok = false
	for _, asset := range assets {
		assetName := *asset.Name
		if nameFilter != "" && !strings.Contains(assetName, nameFilter) {
			continue
		}
		if strings.HasSuffix(assetName, ".zip") {
			assetDetails.Url = *asset.BrowserDownloadURL
			assetDetails.Filename = assetName
			ok = true
		}
		if strings.HasSuffix(assetName, "SHA256SUM.txt") {
			assetDetails.Sha = downloadSha(*asset.BrowserDownloadURL, repoName)
		}
	}
	return assetDetails, ok
}

func main() {
	var result *Buildpacks
	err := yaml.NewDecoder(os.Stdin).Decode(&result)
	if err != nil {
		log.Fatalf("could not unmarshal YAML from stdin: %v", err)
	}

	ctx := context.Background()
	var githubClient *github.Client
	githubToken, ok := os.LookupEnv("GITHUB_API_TOKEN")
	if !ok {
		log.Printf("environment variable GITHUB_API_TOKEN not set. If GitHub communication errors are seen, you may need to export a token with 'public_repo' access")
		githubClient = github.NewClient(nil)
	} else {
		ts := oauth2.StaticTokenSource(&oauth2.Token{AccessToken: githubToken})
		tc := oauth2.NewClient(ctx, ts)
		githubClient = github.NewClient(tc)
	}

	flag.Parse()
	buildpacks_to_update := map[string]bool{}
	args := flag.Args()
	if len(args) == 0 {
		log.Printf("Will update all buildpacks in the configuration file")
		for _, buildpack := range result.Buildpacks {
			buildpacks_to_update[buildpack.Name] = true
		}
	} else {
		log.Printf("Will update the following buildpacks if they existin the configuration file: %v", args)
		for _, arg := range args {
			buildpacks_to_update[arg] = true
		}
	}

	buildpackConfig := Buildpacks{}
	for _, buildpack := range result.Buildpacks {
		log.Printf("Checking %s", buildpack.Name)
		if _, found := buildpacks_to_update[buildpack.Name]; !found {
			log.Printf("Skipping updating %s (%s) because it was not given as an argumetn\n", buildpack.Name, buildpack.Stack)
			buildpackConfig.Buildpacks = append(buildpackConfig.Buildpacks, buildpack)
			continue
		}

		log.Printf("Processing %s (%s)\n", buildpack.Name, buildpack.Stack)
		latestRelease, _, err := githubClient.Repositories.GetLatestRelease(ctx, "cloudfoundry", buildpack.RepoName)
		if err != nil {
			log.Fatalf("could not get latest release for %s, %v", buildpack.RepoName, err)
		}

		assetDetails, ok := getAssetDetails(latestRelease.Assets, buildpack.RepoName, buildpack.Stack)
		if !ok {
			assetDetails, ok = getAssetDetails(latestRelease.Assets, buildpack.RepoName, "")
			if !ok {
				log.Fatalf("could not find assets for release %s", *latestRelease.URL)
			}
		}

		manifest := readManifest(ctx, githubClient, buildpack, latestRelease)
		if assetDetails.Sha == "" {
			log.Printf("SHA for %s %s could not be read. Downloading %s to determine correct SHA for buildpack config.\n", buildpack.Name, *latestRelease.TagName, assetDetails.Url)
			assetDetails.Sha = getAssetSha(assetDetails)

		}
		newBuildpack := Buildpack{
			Name:         buildpack.Name,
			RepoName:     buildpack.RepoName,
			Stack:        buildpack.Stack,
			Filename:     assetDetails.Filename,
			Sha:          assetDetails.Sha,
			Url:          assetDetails.Url,
			Version:      *latestRelease.TagName,
			Dependencies: manifest.Dependencies,
		}

		buildpackConfig.Buildpacks = append(buildpackConfig.Buildpacks, newBuildpack)
	}
	newBuildpacksYaml, err := yaml.Marshal(buildpackConfig)
	if err != nil {
		log.Fatalf("could not marshal buildpackConfig into yaml, %v", err)
	}
	fmt.Print(string(newBuildpacksYaml))
}
