package uaa

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/url"

	pc "github.com/cloudfoundry-community/go-uaa/passwordcredentials"
	"golang.org/x/oauth2"
	cc "golang.org/x/oauth2/clientcredentials"
)

//go:generate go run ./generator/generator.go

// API is a client to the UAA API.
type API struct {
	AuthenticatedClient       *http.Client
	UnauthenticatedClient     *http.Client
	TargetURL                 *url.URL
	skipSSLValidation         bool
	Verbose                   bool
	ZoneID                    string
	UserAgent                 string
	token                     *oauth2.Token
	target                    string
	mode                      mode
	clientID                  string
	clientSecret              string
	username                  string
	password                  string
	authorizationCode         string
	refreshToken              string
	tokenFormat               TokenFormat
	clientCredentialsConfig   *cc.Config
	passwordCredentialsConfig *pc.Config
	oauthConfig               *oauth2.Config
}

// TokenFormat is the format of a token.
type TokenFormat int

// Valid TokenFormat values.
const (
	OpaqueToken TokenFormat = iota
	JSONWebToken
)

func (t TokenFormat) String() string {
	if t == OpaqueToken {
		return "opaque"
	}
	if t == JSONWebToken {
		return "jwt"
	}
	return ""
}

type mode int

const (
	custom mode = iota
	token
	clientcredentials
	passwordcredentials
	authorizationcode
	refreshtoken
)

func New(target string, zoneID string) *API {
	a := &API{
		ZoneID:    zoneID,
		UserAgent: "go-uaa",
		target:    target,
		mode:      custom,
	}
	return a.WithClient(defaultClient())
}

func defaultClient() *http.Client {
	return &http.Client{Transport: http.DefaultTransport}
}

func (a *API) validateTarget() error {
	if a.TargetURL != nil {
		return nil
	}
	if a.target == "" && a.TargetURL == nil {
		return errors.New("the target is missing")
	}
	u, err := BuildTargetURL(a.target)
	if err != nil {
		return err
	}
	a.TargetURL = u
	return nil
}

func (a *API) Validate() error {
	err := a.validateTarget()
	if err != nil {
		return err
	}
	switch a.mode {
	case token:
		err = a.validateToken()
	case clientcredentials:
		err = a.validateClientCredentials()
	case passwordcredentials:
		err = a.validatePasswordCredentials()
	case authorizationcode:
		err = a.validateAuthorizationCode()
	case refreshtoken:
		err = a.validateRefreshToken()
	}
	if err != nil {
		return err
	}
	return a.ensureTransports()
}

func (a *API) WithClient(client *http.Client) *API {
	a.UnauthenticatedClient = client
	_ = a.Validate()
	return a
}

func (a *API) WithSkipSSLValidation(skipSSLValidation bool) *API {
	a.skipSSLValidation = skipSSLValidation
	_ = a.Validate()
	return a
}

// NewWithClientCredentials builds an API that uses the client credentials grant
// to get a token for use with the UAA API.
func NewWithClientCredentials(target string, zoneID string, clientID string, clientSecret string, tokenFormat TokenFormat, skipSSLValidation bool) (*API, error) {
	a := New(target, zoneID).WithClientCredentials(clientID, clientSecret, tokenFormat).WithSkipSSLValidation(skipSSLValidation)
	err := a.Validate()
	if err != nil {
		return nil, err
	}
	return a, err
}

func (a *API) WithClientCredentials(clientID string, clientSecret string, tokenFormat TokenFormat) *API {
	a.mode = clientcredentials
	a.clientID = clientID
	a.clientSecret = clientSecret
	a.tokenFormat = tokenFormat
	_ = a.Validate()
	return a
}

func (a *API) validateClientCredentials() error {
	err := a.validateTarget()
	if err != nil {
		return err
	}
	tokenURL := urlWithPath(*a.TargetURL, "/oauth/token")
	v := url.Values{}
	v.Add("token_format", a.tokenFormat.String())
	c := &cc.Config{
		ClientID:       a.clientID,
		ClientSecret:   a.clientSecret,
		TokenURL:       tokenURL.String(),
		EndpointParams: v,
		AuthStyle:      oauth2.AuthStyleInHeader,
	}
	a.clientCredentialsConfig = c
	a.AuthenticatedClient = c.Client(context.WithValue(context.Background(), oauth2.HTTPClient, a.UnauthenticatedClient))
	return a.ensureTransports()
}

// NewWithPasswordCredentials builds an API that uses the password credentials
// grant to get a token for use with the UAA API.
func NewWithPasswordCredentials(target string, zoneID string, clientID string, clientSecret string, username string, password string, tokenFormat TokenFormat, skipSSLValidation bool) (*API, error) {
	a := New(target, zoneID).WithPasswordCredentials(clientID, clientSecret, username, password, tokenFormat).WithSkipSSLValidation(skipSSLValidation)
	err := a.Validate()
	if err != nil {
		return nil, err
	}
	return a, err
}

func (a *API) WithPasswordCredentials(clientID string, clientSecret string, username string, password string, tokenFormat TokenFormat) *API {
	a.mode = passwordcredentials
	a.clientID = clientID
	a.clientSecret = clientSecret
	a.username = username
	a.password = password
	a.tokenFormat = tokenFormat
	_ = a.Validate()
	return a
}

func (a *API) validatePasswordCredentials() error {
	err := a.validateTarget()
	if err != nil {
		return err
	}
	tokenURL := urlWithPath(*a.TargetURL, "/oauth/token")
	v := url.Values{}
	v.Add("token_format", a.tokenFormat.String())
	c := &pc.Config{
		ClientID:     a.clientID,
		ClientSecret: a.clientSecret,
		Username:     a.username,
		Password:     a.password,
		Endpoint: oauth2.Endpoint{
			TokenURL: tokenURL.String(),
		},
		EndpointParams: v,
	}
	a.passwordCredentialsConfig = c
	a.AuthenticatedClient = c.Client(context.WithValue(context.Background(), oauth2.HTTPClient, a.UnauthenticatedClient))
	return a.ensureTransports()
}

type tokenTransport struct {
	underlyingTransport http.RoundTripper
	token               oauth2.Token
}

func (t *tokenTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	req.Header.Set("Authorization", fmt.Sprintf("%s %s", t.token.Type(), t.token.AccessToken))
	return t.underlyingTransport.RoundTrip(req)
}

// NewWithToken builds an API that uses the given token to make authenticated
// requests to the UAA API.
func NewWithToken(target string, zoneID string, token oauth2.Token) (*API, error) {
	a := New(target, zoneID).WithToken(token)
	err := a.Validate()
	if err != nil {
		return nil, err
	}
	return a, err
}

func (a *API) WithToken(t oauth2.Token) *API {
	a.mode = token
	a.token = &t
	_ = a.Validate()
	return a
}

func (a *API) validateToken() error {
	if !a.token.Valid() {
		return errors.New("access token is not valid, or is expired")
	}

	tokenClient := &http.Client{
		Transport: &tokenTransport{
			underlyingTransport: a.UnauthenticatedClient.Transport,
			token:               *a.token,
		},
	}

	a.AuthenticatedClient = tokenClient
	return a.ensureTransports()
}

func (a *API) Token(ctx context.Context) (*oauth2.Token, error) {
	switch a.mode {
	case token:
		if !a.token.Valid() {
			return nil, errors.New("you have supplied an empty, invalid, or expired token to go-uaa")
		}
		return a.token, nil
	case clientcredentials:
		if a.clientCredentialsConfig == nil {
			return nil, errors.New("you have supplied invalid client credentials configuration to go-uaa")
		}
		return a.clientCredentialsConfig.Token(ctx)
	case authorizationcode:
		if a.oauthConfig == nil {
			return nil, errors.New("you have supplied invalid authorization code configuration to go-uaa")
		}
		if a.UnauthenticatedClient == nil {
			a = a.WithClient(defaultClient())
		}
		ctx := context.WithValue(ctx, oauth2.HTTPClient, a.UnauthenticatedClient)
		tokenFormatParam := oauth2.SetAuthURLParam("token_format", a.tokenFormat.String())
		responseTypeParam := oauth2.SetAuthURLParam("response_type", "token")

		return a.oauthConfig.Exchange(ctx, a.authorizationCode, tokenFormatParam, responseTypeParam)
	case refreshtoken:
		if a.oauthConfig == nil {
			return nil, errors.New("you have supplied invalid refresh token configuration to go-uaa")
		}
		if a.UnauthenticatedClient == nil {
			a = a.WithClient(defaultClient())
		}
		ctx := context.WithValue(context.Background(), oauth2.HTTPClient, a.UnauthenticatedClient)
		tokenSource := a.oauthConfig.TokenSource(ctx, &oauth2.Token{
			RefreshToken: a.refreshToken,
		})

		return tokenSource.Token()
	}
	return nil, errors.New("your configuration provides no way for go-uaa to get a token")
}

// NewWithAuthorizationCode builds an API that uses the authorization code
// grant to get a token for use with the UAA API.
func NewWithAuthorizationCode(target string, zoneID string, clientID string, clientSecret string, authorizationCode string, tokenFormat TokenFormat, skipSSLValidation bool) (*API, error) {
	a := New(target, zoneID).WithSkipSSLValidation(skipSSLValidation).WithAuthorizationCode(clientID, clientSecret, authorizationCode, tokenFormat)
	err := a.Validate()
	if err != nil {
		return nil, err
	}
	return a, err
}

func (a *API) WithAuthorizationCode(clientID string, clientSecret string, authorizationCode string, tokenFormat TokenFormat) *API {
	a.mode = authorizationcode
	a.clientID = clientID
	a.clientSecret = clientSecret
	a.authorizationCode = authorizationCode
	a.tokenFormat = tokenFormat
	_ = a.Validate()
	return a
}

func (a *API) validateAuthorizationCode() error {
	err := a.validateTarget()
	if err != nil {
		return err
	}
	tokenURL := urlWithPath(*a.TargetURL, "/oauth/token")
	c := &oauth2.Config{
		ClientID:     a.clientID,
		ClientSecret: a.clientSecret,
		Endpoint: oauth2.Endpoint{
			TokenURL:  tokenURL.String(),
			AuthStyle: oauth2.AuthStyleInHeader,
		},
	}
	a.oauthConfig = c
	if a.UnauthenticatedClient == nil {
		a = a.WithClient(defaultClient())
	}
	ctx := context.WithValue(context.Background(), oauth2.HTTPClient, a.UnauthenticatedClient)

	if !a.token.Valid() {
		t, err := a.Token(context.Background())
		if err != nil {
			return err
		}
		a.token = t
	}

	a.AuthenticatedClient = c.Client(ctx, a.token)
	return a.ensureTransports()
}

// NewWithRefreshToken builds an API that uses the given refresh token to get an
// access token for use with the UAA API.
func NewWithRefreshToken(target string, zoneID string, clientID string, clientSecret string, refreshToken string, tokenFormat TokenFormat, skipSSLValidation bool) (*API, error) {
	a := New(target, zoneID).WithSkipSSLValidation(skipSSLValidation).WithRefreshToken(clientID, clientSecret, refreshToken, tokenFormat)
	err := a.Validate()
	if err != nil {
		return nil, err
	}
	return a, err
}

func (a *API) WithRefreshToken(clientID string, clientSecret string, refreshToken string, tokenFormat TokenFormat) *API {
	a.mode = refreshtoken
	a.clientID = clientID
	a.clientSecret = clientSecret
	a.refreshToken = refreshToken
	a.tokenFormat = tokenFormat
	_ = a.Validate()
	return a
}

func (a *API) validateRefreshToken() error {
	err := a.validateTarget()
	if err != nil {
		return err
	}
	tokenURL := urlWithPath(*a.TargetURL, "/oauth/token")
	query := tokenURL.Query()
	query.Set("token_format", a.tokenFormat.String())
	tokenURL.RawQuery = query.Encode()
	c := &oauth2.Config{
		ClientID:     a.clientID,
		ClientSecret: a.clientSecret,
		Endpoint: oauth2.Endpoint{
			TokenURL:  tokenURL.String(),
			AuthStyle: oauth2.AuthStyleInHeader,
		},
	}
	a.oauthConfig = c
	ctx := context.WithValue(context.Background(), oauth2.HTTPClient, a.UnauthenticatedClient)

	if !a.token.Valid() {
		t, err := a.Token(context.Background())
		if err != nil {
			return err
		}
		a.token = t
	}

	a.AuthenticatedClient = c.Client(ctx, a.token)
	return a.ensureTransports()
}
