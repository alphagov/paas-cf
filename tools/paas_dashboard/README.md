We use [Smashing](https://github.com/Dashing-io/smashing) to aggregate
various monitoring into a system overview on the `paas-overview` dashboard.

### Principles

We want a strong visual signal of health at a distance, so prefer big
red/green boxes to using a variety of more fiddly widgets.

We want separate health signals per-environment.

We don't want the display to distract, so avoid flickering, pulsing, scrolling and so on.

We want to provide a system overview that is also a useful starting point
for investigating failures. So each box should link to more detail.
 
If we decide to provide more detailed views with Smashing, they belong on a separate dashboard.

### Smashing basics

Smashing is a [Sinatra](http://www.sinatrarb.com/) webapp.
It uses [Sprockets](https://github.com/rails/sprockets) to pull together various scss and coffeescript into a single glorious lump.

Look at `dashboards` for the dashboard html/erb, `jobs` for the ruby code that pulls values for binding to the dashboards, and `widgets` for the display components which know what to do with the bound data.

You can also push json data into particular data-bindings using an http api, but we don't expect to need to integrate any monitoring in that direction.

Smashing is a recent descendant of the now-defunct Dashing project.
See [dashing.io](http://dashing.io) and the [smashing wiki](https://github.com/dashing-io/smashing/wiki) for docs.

### Our deployment

We deploy our smashing app as part of the `create-bosh-cloudfoundry` pipeline.
It should be available [here](https://paas-dashboard.cloudapps.digital)

### Running locally

Obtain API and app keys from https://app.datadoghq.com/account/settings#api

```bundle install
 DD_API_KEY=<api key> DD_APP_KEY=<app key> bundle exec smashing start```
