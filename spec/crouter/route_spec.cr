require "../spec_helper"

def empty_action
  -> (request : HTTP::Request, params : HTTP::Params) { HTTP::Response.new(200) }
end

def route(pattern, action = empty_action)
  Crouter::Route.new("GET", pattern, action)
end

describe Crouter::Route do
  describe ".new" do
    it "raises if a pattern not starting with '/' is passed" do
      pattern = "test"
      expect_raises Crouter::Route::Error, "failed to parse route pattern `#{pattern}' - must start with /" do
        route(pattern)
      end
      route("/test")
    end

    it "raises if a pattern has optional parts in the middle" do
      ["/foo(/:optional)/:bar", "/foo(/:optional)(/:bar)"].each do |pattern|
        message = "failed to parse route pattern `#{pattern}' - optional parts must be right aligned"
        expect_raises Crouter::Route::Error, message do
          route(pattern)
        end
      end
      route("/foo/:bar(/:optional)")
    end
  end

  describe "#match" do
    it "returns a match object with the named groups as defined in the pattern" do
      route = route("/foo/:bar(/:optional)")
      match = route.match("GET", "/foo/test1")
      match.should_not be_nil
      match = match.not_nil!
      match["bar"].should eq("test1")
      match["optional"]?.should be_nil
    end

    it "escapes special regex chars" do
      route = route("/foo/:bar(/:optional(.:format))")
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
      route = route("/foo/:bar(/:optional(.:format))")
      match = route.match("GET", "/foo/test1/test2.json?foo=bar")
      match.should_not be_nil
    end

    it "allows slashes in params" do
      route = route("/foo/:bar/baz")
      match = route.match("GET", "/foo/bar/foobar/baz")
      match.should_not be_nil
    end
  end

  describe "#call_action" do
    it "calls the action passed to the initializer with the passed request and params" do
      action = -> (request : HTTP::Request, params : HTTP::Params) {
        params["bar"].should eq("test1")
        params["optional"]?.should eq("test2")
        params["format"]?.should eq("json")
        params["query1"]?.should eq("test3")
        params["query2"]?.should eq("test4")
        HTTP::Response.new(200)
      }
      route = route("/foo/:bar(/:optional(.:format))", action)
      path = "/foo/test1/test2.json?query1=test3&query2=test4"
      request = HTTP::Request.new("GET", path)
      match = route.match("GET", path)
      match.should_not be_nil
      route.call_action(request, match.not_nil!)
    end
  end
end
