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
    HTTP::Response.new(200)
  end

  def bar
    Spy.bar
    params["bar"]?.should eq("foo")
    HTTP::Response.new(200)
  end
end

module TestRouter
  include Crouter

  get "/foo(/:bar)", "TestController#foo"
  post "/foo(/:bar)", "TestController#bar"
  post "/foo/foo" do
    Spy.first_block
    HTTP::Response.new(200)
  end

  post "/bar" do
    Spy.second_block
    params["test"].should eq("foobar")
    HTTP::Response.new(200)
  end

  get "/return.:format" do
    case params["format"]
    when "json" then HTTP::Response.new(200, %({"test":"foobar"}))
    when "xml" then HTTP::Response.new(200, %(<?xml version="1.0" encoding="utf-8"?><test>foobar</test>))
    else HTTP::Response.new(400, "invalid format")
    end
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

    it "returns a response with code 404 if no route matches" do
      request = HTTP::Request.new("GET", "/non-existing/route")
      result = TestRouter.route(request)
      result.status_code.should eq(404)
    end

    it "returns an http response" do
      request = HTTP::Request.new("GET", "/return.json")
      result = TestRouter.route(request)
      result.should be_a(HTTP::Response)
      result.body.should eq(%({"test":"foobar"}))
    end
  end
end
