# crouter

A standalone router for crystal

## Features

- route params (also optional and nested optional)
- grouping under a prefix
- handle response with either block or seperate controller
- support for query params (also mixed with route params)
- most errors reveal themselves already at compile time

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crouter:
    github: jreinert/crouter
```

## Usage

```crystal
require "crouter"

class MyController
  private getter request, params
  def initialize(@request, @params)
  end

  def my_action
    # do something
    HTTP::Response.new(200, "hi there")
  end
end

module MyRouter
  include Crouter

  get "/some/path" do
    HTTP::Response.new(200, "hello world")
  end

  post "/path/with/:param" do
    HTTP::Response.new(200, "you passed #{params["param"]}")
  end

  get "/path/with(/optional(/:parts))" do
    HTTP::Response.new(200, "you passed #{params["parts"]? || "nothing"}")
  end

  put "/handle/with/controller", "MyController#my_action"

  group "/group" do
    put "/routes", "MyGroupController#my_action"
    group "/or/even/:nest" do
      post "/them" do
        HTTP::Response.new(200, "with params! #{params["nest"]}")
      end
    end
  end
end

puts "Listening on http://localhost:8989"
HTTP::Server.new(8989) { |request| MyRouter.route(request) }
```

## Contributing

1. Fork it ( https://github.com/jreinert/crouter/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [jreinert](https://github.com/jreinert) Joakim Reinert - creator, maintainer
