require "./crouter/*"
require "http"

module Crouter
  macro included
    {% methods = %i(GET POST PUT PATCH DELETE) %}
    ROUTES = {
      {% for method in methods %}
        {{method.id}}: {} of String => Array(Route),
      {% end %}
    }

    def self.route(request) : HTTP::Response
      case(request.method)
      {% for method in methods %}
        when {{method.id.stringify}}
          path = request.path || ""
          (1...path.size).each do |i|
            path_slice = path[0..-i]
            next unless routes = ROUTES[{{method}}][path_slice]?
            routes.each do |route|
              next unless match = route.match(path)
              return route.call_action(request, match)
            end
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
        \{% static_part = %["\#{Route.prefix}#{pattern.id}".gsub(/(\\:|\\().*/, "")] %}
        ROUTES[{{method}}][\{{static_part.id}}] ||= [] of Route
        ROUTES[{{method}}][\{{static_part.id}}] << Route.new(\{{pattern}}, \{{action.id}})
      end

      macro {{method.downcase.id}}(pattern)
        \{% action = "-> (request : HTTP::Request, params : HTTP::Params) { #{yield} }" %}
        \{% static_part = %["\#{Route.prefix}#{pattern.id}".gsub(/(\\:|\\().*/, "")] %}
        ROUTES[{{method}}][\{{static_part.id}}] ||= [] of Route
        ROUTES[{{method}}][\{{static_part.id}}] << Route.new(\{{pattern}}, \{{action.id}})
      end
    {% end %}
  end
end
