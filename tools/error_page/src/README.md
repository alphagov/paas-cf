# Error Page Generator

A small nodeJS application, used to compile GOV.UK SASS and create a self-contained static HTML page, to be used for
CloudFoundry's gorouter.

## Usage

### Install dependencies

You should make sure you have all the dependencies required for this to be built.

```sh
npm install
```

### Build

You can build the YAML file for `manifests/cf-manifest/operations.d` with:

```sh
npm run -s build | pbcopy
# or directly write into the file
npm run -s build > ../../manifests/cf-manifest/operations.d/310-router-custom-error-page.yml
```

### Run locally

You can also run the application locally to make some changes and see the results instantly.

```sh
npm run start
```

Served under `$PORT` or `3000` ports.
