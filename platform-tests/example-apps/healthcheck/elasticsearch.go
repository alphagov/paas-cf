package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"net/url"
)

func elasticsearchHandler(w http.ResponseWriter, r *http.Request) {
	tls := r.FormValue("tls") != "false"

	err := testElasticsearchConnection(tls)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	writeJson(w, map[string]interface{}{
		"success": true,
	})
}

func testElasticsearchConnection(tls bool) error {
	var credentials struct {
		URI string `json:"uri"`
	}
	err := getVCAPServiceCredentials("elasticsearch", &credentials)
	if err != nil {
		return err
	}
	if !tls {
		credentials.URI, err = forcePlainHTTP(credentials.URI)
		if err != nil {
			return err
		}
	}
	client := &esClient{
		client:  &http.Client{},
		baseURL: credentials.URI,
	}

	// Insert document
	err = client.InsertDocument("test_index", "test_type", "42", map[string]string{"title": "Test document"})
	if err != nil {
		return err
	}

	// Read document
	doc, err := client.GetDocument("test_index", "test_type", "42")
	if err != nil {
		return err
	}
	if doc.Source["title"] != "Test document" {
		return fmt.Errorf("Unexpected data back from ES: %#v", doc)
	}

	// Delete document
	err = client.DeleteDocument("test_index", "test_type", "42")
	if err != nil {
		return err
	}

	return nil
}

type esDocument struct {
	Index  string                 `json:"_index"`
	Type   string                 `json:"_type"`
	ID     string                 `json:"_id"`
	Source map[string]interface{} `json:"_source"`
}

type esClient struct {
	client  *http.Client
	baseURL string
}

func (e *esClient) DocumentUrl(index, kind, id string) string {
	esURL := &url.URL{}
	esURL, _ = esURL.Parse(e.baseURL)
	path := fmt.Sprintf("/%s/%s/%s", index, kind, id)
	esURL.Path = path
	return esURL.String()
}

func (e *esClient) GetDocument(index, kind, id string) (*esDocument, error) {
	resp, err := e.doRequest("GET", e.DocumentUrl(index, kind, id), nil, 200)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	var doc esDocument
	err = json.NewDecoder(resp.Body).Decode(&doc)
	return &doc, err
}

func (e *esClient) InsertDocument(index, kind, id string, data interface{}) error {
	var body bytes.Buffer
	err := json.NewEncoder(&body).Encode(data)
	if err != nil {
		return err
	}

	_, err = e.doRequest("PUT", e.DocumentUrl(index, kind, id), &body, 201)
	return err
}

func (e *esClient) DeleteDocument(index, kind, id string) error {
	_, err := e.doRequest("DELETE", e.DocumentUrl(index, kind, id), nil, 200)
	return err
}

func (e *esClient) doRequest(method, url string, body io.Reader, expectedStatus int) (*http.Response, error) {
	req, err := http.NewRequest(method, url, body)
	if err != nil {
		return nil, err
	}
	req.Header.Add("Content-Type", "application/json")
	resp, err := e.client.Do(req)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode != expectedStatus {
		respBody, _ := ioutil.ReadAll(resp.Body)
		resp.Body.Close()
		return nil, fmt.Errorf("Expected %d, got %d response\n%s\n", expectedStatus, resp.StatusCode, string(respBody))
	}
	return resp, nil
}
