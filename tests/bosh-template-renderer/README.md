Hello!

```
  $ bundle install
  $ cat /tmp/template
  <%= p("hello.sup") %>
  $ cat /tmp/spec
  properties:
    hello.sup:
      description: "Sup yo!"
      default: "default value"
  $ cat /tmp/empty-manifest
  properties: {}
  $ cat /tmp/manifest
  properties:
    hello:
      sup: Keep on rocki'n in the free world
  $ ruby render.rb /tmp/template /tmp/spec /tmp/empty-manifest
  default value
  $ ruby render.rb /tmp/template /tmp/spec /tmp/manifest
  Keep on rocki'n in the free world
```
