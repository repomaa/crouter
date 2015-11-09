require "./crouter/*"
require "http"

module Crouter
  macro included
    {% methods = %i(GET POST PUT PATCH DELETE) %}
    ROUTES = {
      {% for method in methods %}
        {{method.id}}: [] of Route,
      {% end %}
    }

    def self.route(request)
      case(request.method)
      {% for method in methods %}
        when {{method.id.stringify}}
          ROUTES[{{method}}].each do |route|
            next unless match = route.match(request.path || "")
            return route.call_action(request, match)
          end
      {% end %}
      end

      HTTP::Response.new(404, "No route found for #{request.method} #{request.path}")
    end

    macro group(prefix)
      Route.prefixed(\{{prefix}}) { \{{yield}} }
    end

    {% for method in methods %}
      macro {{method.downcase.id}}(pattern, action)
        \{% action_error = "action must be either a string of the form `Controller#action' or a Proc" %}
        \{% if action.is_a?(StringLiteral) %}
          \{% controller = action.split("#")[0] %}
          \{% action = action.split("#")[1] %}
          \{% raise(action_error) unless controller && action %}
          \{% action = "-> (request : HTTP::Request, params : HTTP::Params) { controller = #{controller.id}.new(request, params); controller.#{action.id} }" %}
        \{% elsif !action.is_a?(FunLiteral) %}
           \{% raise(action_error) %}
        \{% end %}
        ROUTES[{{method}}] << Route.new(\{{pattern}}, \{{action.id}})
      end

      macro {{method.downcase.id}}(pattern)
        \{% action = "-> (request : HTTP::Request, params : HTTP::Params) { #{yield} }" %}
        ROUTES[{{method}}] << Route.new(\{{pattern}}, \{{action.id}})
      end
    {% end %}
  end
end
