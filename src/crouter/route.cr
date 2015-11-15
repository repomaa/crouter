module Crouter
  class Route
    class Error < Exception
      def initialize(pattern, message)
        super("failed to parse route pattern `#{pattern}' - #{message}")
      end
    end

    @@prefix = ""
    def self.prefixed(prefix : String)
      old_prefix = @@prefix
      @@prefix = "#{old_prefix}#{prefix}"
      yield
    ensure
      @@prefix = old_prefix
    end

    def self.prefix
      @@prefix
    end

    def initialize(@method, pattern, @action : (HTTP::Request, HTTP::Params) -> HTTP::Response?)
      original_pattern = "#{@@prefix}#{pattern}"
      pattern = original_pattern.gsub(/\/$/, "")

      raise Error.new(pattern, "must start with /") unless original_pattern[0] == '/'
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
          "(?<#{m[1]}>(?:[A-Za-z0-9\\-._~/!$&'()*+,;=:@]|%[a-fA-F0-9]{2}?)+?)"
        end

      @matcher = /^#{pattern}\/?($|\?.*)/
      puts "set up route #{@method} #{original_pattern}"
    end

    def match(method, path)
      return nil unless method == @method
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
