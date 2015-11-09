# crouter [![Build Status](https://travis-ci.org/jreinert/crouter.svg?branch=master)](https://travis-ci.org/jreinert/crouter)

A standalone router for crystal

## Features

- route params (also optional and nested optional)
- grouping under a prefix
- handle response with either block or seperate controller
- support for query params (also mixed with route params)
- most errors reveal themselves already at compile time

## Benchmark results

Benchmarked with non-trivial route patterns. See
[src/benchmark.cr](src/benchmark.cr)

```
requests per second
without router (raw server throughput)   9.86k (± 9.70%)       fastest
         through router with 32 routes   8.68k (± 6.35%)  1.13× slower
         through router with 64 routes   8.82k (± 9.57%)  1.12× slower
        through router with 128 routes   7.76k (± 8.71%)  1.27× slower
        through router with 256 routes   6.33k (± 5.79%)  1.56× slower
        through router with 512 routes    5.1k (± 3.58%)  1.93× slower
       through router with 1024 routes   3.41k (± 4.22%)  2.89× slower
       through router with 2048 routes   2.02k (± 8.13%)  4.88× slower
       through router with 4096 routes    939  (±23.32%) 10.50× slower
```

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
