require "./route"
require "http/server"

module Crouter
  abstract class Router < HTTP::Handler
    abstract def call(context)

    macro inherited
      {% methods = %i(GET POST PUT PATCH DELETE) %}
      ROUTES = {} of String => Array(Crouter::Route)

      def self.routes
        ROUTES
      end

      def call(context)
        path = context.request.path || "/"
        return call_next(context) unless path.starts_with?(@mountpoint)
        path = path[@mountpoint.size..-1]
        (1..path.size).each do |i|
          path_slice = path[0..-i]
          next unless routes = self.class.routes[path_slice]?
          routes.each do |route|
            next unless match = route.match(context.request.method, path)
            return route.call_action(context, match)
          end
        end

        call_next(context)
      end

      macro group(prefix)
        Crouter::Route.prefixed(\{{prefix}}) { \{{yield}} }
      end

      {% for method in methods %}
        macro {{method.downcase.id}}(pattern, action)
          \{% action_error = "action must be either a string of the form `Controller#action' or a Proc" %}
          \{% if action.is_a?(StringLiteral) %}
            \{% controller = action.split("#")[0] %}
            \{% action = action.split("#")[1] %}
            \{% raise(action_error) unless controller && action %}
            \{% action = "-> (context : HTTP::Server::Context, params : HTTP::Params) { controller = #{controller.id}.new(context, params); controller.#{action.id}; nil }" %}
          \{% elsif !action.is_a?(FunLiteral) %}
             \{% raise(action_error) %}
          \{% end %}
          \{% static_part = %["\#{Crouter::Route.prefix}#{pattern.id}".gsub(/(\\:|\\(|\\/$).*/, "")] %}
          ROUTES[\{{static_part.id}}] ||= [] of Crouter::Route
          ROUTES[\{{static_part.id}}] << Crouter::Route.new({{method.id.stringify}}, \{{pattern}}, \{{action.id}})
        end

        macro {{method.downcase.id}}(pattern)
          \{% action = "-> (context : HTTP::Server::Context, params : HTTP::Params) { #{yield}; nil }" %}
          {{method.downcase.id}}(\{{pattern}}, \{{action.id}})
        end
      {% end %}
    end

    @mountpoint : String

    def initialize(mountpoint = "")
      @mountpoint = mountpoint.gsub(/\/$/, "")
    end
  end
end
