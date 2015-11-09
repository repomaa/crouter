require "../spec_helper"

def empty_action
  -> (request : HTTP::Request, params : HTTP::Params) { HTTP::Response.new(200) }
end

module Crouter
  describe Route do
    describe ".new" do
      it "raises if a pattern not starting with '/' is passed" do
        pattern = "test"
        expect_raises Route::Error, "failed to parse route pattern `#{pattern}' - must start with /" do
          Route.new(pattern, empty_action)
        end
        Route.new("/test", empty_action)
      end

      it "raises if a pattern has optional parts in the middle" do
        ["/foo(/:optional)/:bar", "/foo(/:optional)(/:bar)"].each do |pattern|
          message = "failed to parse route pattern `#{pattern}' - optional parts must be right aligned"
          expect_raises Route::Error, message do
            Route.new(pattern, empty_action)
          end
        end
        Route.new("/foo/:bar(/:optional)", empty_action)
      end
    end

    describe "#match" do
      it "returns a match object with the named groups as defined in the pattern" do
        route = Route.new("/foo/:bar(/:optional)", empty_action)
        match = route.match("/foo/test1")
        match.should_not be_nil
        match = match.not_nil!
        match["bar"].should eq("test1")
        match["optional"]?.should be_nil
      end

      it "escapes special regex chars" do
        route = Route.new("/foo/:bar(/:optional(.:format))", empty_action)
        match = route.match("/foo/test1/test2.json")
        match.should_not be_nil
        match = match.not_nil!
        match["format"].should eq("json")
        match = route.match("/foo/test1:json")
        match.should be_nil
      end

      it "matches paths with query params" do
        route = Route.new("/foo/:bar(/:optional(.:format))", empty_action)
        match = route.match("/foo/test1/test2.json?foo=bar")
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
        route = Route.new("/foo/:bar(/:optional(.:format))", action)
        path = "/foo/test1/test2.json?query1=test3&query2=test4"
        request = HTTP::Request.new("GET", path)
        match = route.match(path)
        match.should_not be_nil
        route.call_action(request, match.not_nil!)
      end
    end
  end
end
