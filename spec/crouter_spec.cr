require "./crouter/*"
require "./spec_helper"

call_spy Spy, foo, bar, first_block, second_block

class TestController
  private getter request, params
  def initialize(@request, @params)
  end

  def foo
    Spy.foo
    params["bar"].should eq("bar")
  end

  def bar
    Spy.bar
    params["bar"]?.should eq("foo")
  end
end

module TestRouter
  include Crouter

  get "/foo(/:bar)", "TestController#foo"
  post "/foo(/:bar)", "TestController#bar"
  post "/foo/foo" do
    Spy.first_block
  end

  post "/bar" do
    Spy.second_block
    params["test"].should eq("foobar")
  end
end

describe Crouter do
  describe ".route" do
    it "matches a route for the request method and path and calls its action" do
      Spy.reset!
      request = HTTP::Request.new("GET", "/foo/bar")
      TestRouter.route(request)
      Spy.foo_was_called?.should be_true
      Spy.bar_was_called?.should be_false

      Spy.reset!
      request = HTTP::Request.new("POST", "/foo/foo")
      TestRouter.route(request)
      Spy.bar_was_called?.should be_true
      Spy.foo_was_called?.should be_false
    end

    it "preserves route order and calls only one route" do
      Spy.reset!
      request = HTTP::Request.new("POST", "/foo/foo")
      TestRouter.route(request)
      Spy.bar_was_called?.should be_true
      Spy.first_block_was_called?.should be_false
    end

    it "calls blocks" do
      Spy.reset!
      request = HTTP::Request.new("POST", "/bar?test=foobar")
      TestRouter.route(request)
      Spy.second_block_was_called?.should be_true
    end
  end
end
