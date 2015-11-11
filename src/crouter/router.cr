require "./route"
require "http/server"

module Crouter
  class Router < HTTP::Handler
    def initialize(mountpoint = "")
      @mountpoint = mountpoint.gsub(/\/$/, "")
    end

    macro inherited
      {% methods = %i(GET POST PUT PATCH DELETE) %}
      ROUTES = {
        {% for method in methods %}
          {{method.id}}: {} of String => Array(Crouter::Route),
        {% end %}
      }

      def call(request) : HTTP::Response
        path = request.path || "/"
        return call_next(request) unless path.starts_with?(@mountpoint)
        path = path[@mountpoint.size..-1]
        case(request.method)
        {% for method in methods %}
          when {{method.id.stringify}}
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

        call_next(request)
      end

      macro group(prefix)
        Crouter::Route.prefixed(\{{prefix}}) { \{{yield}} }
      end

      {% for method in methods %}
        macro {{method.downcase.id}}(pattern, action, with_variant = true)
          \{% if with_variant && pattern != "/" %}
            \{% if pattern =~ /\/$/ %}
               {{method.downcase.id}}(\{{pattern.gsub(/\/$/, "")}}, \{{action}}, false)
            \{% else %}
               {{method.downcase.id}}(\{{"#{pattern.id}/"}}, \{{action}}, false)
            \{% end %}
          \{% end %}
          \{% action_error = "action must be either a string of the form `Controller#action' or a Proc" %}
          \{% if action.is_a?(StringLiteral) %}
            \{% controller = action.split("#")[0] %}
            \{% action = action.split("#")[1] %}
            \{% raise(action_error) unless controller && action %}
            \{% action = "-> (request : HTTP::Request, params : HTTP::Params) { controller = #{controller.id}.new(request, params); controller.#{action.id} }" %}
          \{% elsif !action.is_a?(FunLiteral) %}
             \{% raise(action_error) %}
          \{% end %}
          \{% static_part = %["\#{Crouter::Route.prefix}#{pattern.id}".gsub(/(\\:|\\().*/, "")] %}
          ROUTES[{{method}}][\{{static_part.id}}] ||= [] of Crouter::Route
          ROUTES[{{method}}][\{{static_part.id}}] << Crouter::Route.new(\{{pattern}}, \{{action.id}})
        end

        macro {{method.downcase.id}}(pattern)
          \{% action = "-> (request : HTTP::Request, params : HTTP::Params) { #{yield} }" %}
          {{method.downcase.id}}(\{{pattern}}, \{{action.id}})
        end
      {% end %}
    end
  end
end
