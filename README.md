# crouter [![Build Status](https://github.com/jreinert/crouter/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/jreinert/crouter/actions)

A standalone router for crystal

## Features

- route params (also optional and nested optional)
- grouping under a prefix
- handle response with either block or seperate controller
- support for query params (also mixed with route params)
- most errors reveal themselves already at compile time

## Benchmark results

Benchmarked with non-trivial route patterns. See
[src/benchmark.cr](src/benchmark.cr). Due to performance optimizations
compile-time increases with the amount of routes.

```
requests per second
without router (raw server throughput) 345.02k (± 3.91%)       fastest
         through router with 32 routes 248.48k (± 3.56%)  1.39× slower
         through router with 64 routes 251.07k (± 3.57%)  1.37× slower
        through router with 128 routes 126.84k (± 2.49%)  2.72× slower
        through router with 256 routes 167.36k (± 3.69%)  2.06× slower
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
  private getter context, params
  def initialize(@context, @params)
  end

  def my_action
    # do something
    context.response << "hi there"
  end
end

class MyRouter < Crouter::Router
  get "/" do
    context.response << "hello world"
  end

  post "/path/with/:param" do
    context.response << "you passed #{params["param"]}"
  end

  get "/path/with(/optional(/:parts))" do
    context.repsonse << "you passed #{params["parts"]? || "nothing"}"
  end

  put "/handle/with/controller", "MyController#my_action"

  group "/group" do
    put "/routes", "MyGroupController#my_action"
    group "/or/even/:nest" do
      post "/them" do
        context.response << "with params! #{params["nest"]}"
      end
    end
  end
end

class MyRestAPI < Crouter::Router
  group "/posts" do
    get    "/",         "PostsController#index"
    get    "/:id",      "PostsController#show"
    get    "/:id/edit", "PostsController#edit"
    post   "/",         "PostsController#create"
    put    "/:id",      "PostsController#update"
    delete "/:id",      "PostsController#delete"
  end
end

puts "Listening on http://localhost:8989"
HTTP::Server.new(8989, [HTTP::LogHandler.new, MyRestAPI.new("/api"), MyRouter.new])
```

## Contributing

1. Fork it ( https://github.com/jreinert/crouter/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [repomaa](https://github.com/repomaa) Joakim Repomaa - creator, maintainer
- [![Contributors](https://contrib.rocks/image?repo=repomaa/crouter)](https://github.com/repomaa/crouter/graphs/contributors)
