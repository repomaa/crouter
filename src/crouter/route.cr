module Crouter
  class Route
    class Error < Exception
      def initialize(pattern, message)
        super("failed to parse route pattern `#{pattern}' - #{message}")
      end
    end

    def initialize(pattern, @action : (HTTP::Request, HTTP::Params) ->, prefix = "")
      raise Error.new(pattern, "must start with /") unless pattern[0] == '/'
      optional_count = pattern.count("(")
      if pattern[-optional_count, optional_count] != ")" * optional_count
        raise Error.new(pattern, "optional parts must be right aligned")
      end

      @params = [] of String
      pattern = Regex.escape(pattern)
        .gsub("\\(", "(?:")
        .gsub("\\)", ")?")
        .gsub(/\\:(\w+)?/) do |_, m|
          @params << m[1]
          "(?<#{m[1]}>\\w+)"
        end

      @matcher = /^#{Regex.escape(prefix)}#{pattern}($|\?.*)/
    end

    def match(path)
      path.match(@matcher)
    end

    def call_action(request, match)
      @action.call(request, combined_params(request.query_params, match))
    end

    private def combined_params(query_params, match)
      raw_params = {} of String => Array(String)
      query_params.each do |name, value|
        array = raw_params[name] ||= [] of String
        array << value
      end
      @params.each do |name|
        value = match[name]?
        next unless value
        array = raw_params[name] ||= [] of String
        array << value
      end

      HTTP::Params.new(raw_params)
    end
  end
end
