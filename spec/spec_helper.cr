require "spec"
require "../src/crouter"

macro call_spy(module_name, *methods)
  module {{module_name.id}}
    @@called_methods = [] of String

    def self.reset!
      @@called_methods = [] of String
    end

    {% for method in methods %}
      def self.{{method.id}}
        @@called_methods << {{method.id.stringify}}
      end

      def self.{{method.id}}_was_called?
        @@called_methods.includes?({{method.id.stringify}})
      end
    {% end %}
  end
end
