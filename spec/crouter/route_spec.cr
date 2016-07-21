require "../spec_helper"

def empty_action
  -> (context : HTTP::Server::Context, params : HTTP::Params) {}
end

def def_route(pattern, action = empty_action)
  Crouter::Route.new("GET", pattern, action)
end

describe Crouter::Route do
  describe ".new" do
    it "raises if a pattern not starting with '/' is passed" do
      pattern = "test"
      expect_raises Crouter::Route::Error, "failed to parse route pattern `#{pattern}' - must start with /" do
        def_route(pattern)
      end
      def_route("/test")
    end

    it "raises if a pattern has optional parts in the middle" do
      ["/foo(/:optional)/:bar", "/foo(/:optional)(/:bar)"].each do |pattern|
        message = "failed to parse route pattern `#{pattern}' - optional parts must be right aligned"
        expect_raises Crouter::Route::Error, message do
          def_route(pattern)
        end
      end
      def_route("/foo/:bar(/:optional)")
    end
  end

  describe "#match" do
    it "returns a match object with the named groups as defined in the pattern" do
      route = def_route("/foo/:bar(/:optional)")
      match = route.match("GET", "/foo/test1")
      match.should_not be_nil
      match = match.not_nil!
      match["bar"].should eq("test1")
      match["optional"]?.should be_nil
    end

    it "escapes special regex chars" do
      route = def_route("/foo/:bar(/:optional(.:format))")
      match = route.match("GET", "/foo/test1/test2.json")
      match.should_not be_nil
      match = match.not_nil!
      match["format"].should eq("json")
      match = route.match("GET", "/foo/test1:json")
      match.should_not be_nil
      match = match.not_nil!
      match["bar"].should eq("test1:json")
    end

    it "matches paths with query params" do
      route = def_route("/foo/:bar(/:optional(.:format))")
      match = route.match("GET", "/foo/test1/test2.json?foo=bar")
      match.should_not be_nil
    end

    it "allows slashes in params" do
      route = def_route("/foo/:bar/baz")
      match = route.match("GET", "/foo/bar/foobar/baz")
      match.should_not be_nil
    end
  end

  describe "#call_action" do
    it "calls the action passed to the initializer with the passed context and params" do
      action = -> (context : HTTP::Server::Context, params : HTTP::Params) {
        params["bar"].should eq("test1")
        params["optional"]?.should eq("test2")
        params["format"]?.should eq("json")
        params["query1"]?.should eq("test3")
        params["query2"]?.should eq("test4")
      }
      route = def_route("/foo/:bar(/:optional(.:format))", action)
      path = "/foo/test1/test2.json?query1=test3&query2=test4"
      context = HTTP::Server::Context.new(
        HTTP::Request.new("GET", path),
        HTTP::Server::Response.new(MemoryIO.new)
      )
      match = route.match("GET", path)
      match.should_not be_nil
      route.call_action(context, match.not_nil!)
    end

    it "parses a post request body if it's a application/x-www-form-urlencoded" do
      action = -> (context : HTTP::Server::Context, params : HTTP::Params) {
        params["bar"].should eq("test1")
        params["optional"]?.should eq("test2")
        params["format"]?.should eq("json")
        params["form1"]?.should eq("test3")
        params["form2"]?.should eq("test4")
      }
      route = Crouter::Route.new("POST", "/foo/:bar(/:optional(.:format))", action)
      path = "/foo/test1/test2.json"
      form = HTTP::Params.build do |form|
        form.add "form1", "test3"
        form.add "form2", "test4"
      end
      context = HTTP::Server::Context.new(
        HTTP::Request.new(
          "POST", path,
          body: form,
          headers: HTTP::Headers{"Content-Type" => "application/x-www-form-urlencoded"}
        ),
        HTTP::Server::Response.new(MemoryIO.new)
      )
      match = route.match("POST", path)
      match.should_not be_nil
      route.call_action(context, match.not_nil!)
    end
  end
end
