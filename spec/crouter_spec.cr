require "./crouter/*"
require "./spec_helper"

call_spy Spy, foo, bar, first_block, second_block, prefix, without_prefix, sub_prefix, param_prefix, trailing, non_trailing

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
    params["bar"]?.should eq("bar")
    HTTP::Response.new(200)
  end
end

class TestRouter < Crouter::Router
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

  group "/prefix" do
    get "/foo(/:bar)" do
      Spy.prefix
      params["bar"].should eq("foobar")
      HTTP::Response.new(200)
    end

    group "/sub_prefix" do
      get "/foo" do
        Spy.sub_prefix
       HTTP::Response.new(200)
      end
    end
  end

  group "/param_prefix/:foo" do
    get "/bar" do
      Spy.param_prefix
      params["foo"].should eq("test1")
      HTTP::Response.new(200)
    end
  end

  get "/without/prefix" do
    Spy.without_prefix
    HTTP::Response.new(200)
  end

  get "/return.:format" do
    case params["format"]
    when "json" then HTTP::Response.new(200, %({"test":"foobar"}))
    when "xml" then HTTP::Response.new(200, %(<?xml version="1.0" encoding="utf-8"?><test>foobar</test>))
    else HTTP::Response.new(400, "invalid format")
    end
  end

  get "/trailing/" do
    Spy.trailing
    HTTP::Response.new(200)
  end

  get "/non-trailing" do
    Spy.non_trailing
    HTTP::Response.new(200)
  end
end

def route(request)
  TestRouter.new.call(request)
end

describe Crouter do
  describe ".route" do
    it "matches a route for the request method and path and calls its action" do
      Spy.reset!
      request = HTTP::Request.new("GET", "/foo/bar")
      route(request)
      Spy.foo_was_called?.should be_true
      Spy.bar_was_called?.should be_false

      Spy.reset!
      request = HTTP::Request.new("POST", "/foo/bar")
      route(request)
      Spy.bar_was_called?.should be_true
      Spy.foo_was_called?.should be_false
    end

    it "favors static routes and calls only one route" do
      Spy.reset!
      request = HTTP::Request.new("POST", "/foo/foo")
      route(request)
      Spy.first_block_was_called?.should be_true
      Spy.bar_was_called?.should be_false
    end

    it "calls blocks" do
      Spy.reset!
      request = HTTP::Request.new("POST", "/bar?test=foobar")
      route(request)
      Spy.second_block_was_called?.should be_true
    end

    it "returns a response with code 404 if no route matches" do
      request = HTTP::Request.new("GET", "/non-existing/route")
      result = route(request)
      result.status_code.should eq(404)
    end

    it "returns an http response" do
      request = HTTP::Request.new("GET", "/return.json")
      result = route(request)
      result.should be_a(HTTP::Response)
      result.body.should eq(%({"test":"foobar"}))
    end

    it "matches trailing / variants of a route and vice versa" do
      Spy.reset!
      request = HTTP::Request.new("GET", "/trailing")
      route(request)
      Spy.trailing_was_called?.should be_true

      Spy.reset!
      request = HTTP::Request.new("GET", "/non-trailing/")
      route(request)
      Spy.non_trailing_was_called?.should be_true
    end
  end

  describe "group" do
    it "groups underlying routes by prepending a given prefix" do
      Spy.reset!
      request = HTTP::Request.new("GET", "/prefix/foo/foobar")
      route(request)
      Spy.prefix_was_called?.should be_true
    end

    it "it restores the prefix after the block" do
      Spy.reset!
      request = HTTP::Request.new("GET", "/without/prefix")
      route(request)
      Spy.without_prefix_was_called?.should be_true
    end

    it "it supports nesting" do
      Spy.reset!
      request = HTTP::Request.new("GET", "/prefix/sub_prefix/foo")
      route(request)
      Spy.sub_prefix_was_called?.should be_true
    end

    it "it supports params in group prefix" do
      Spy.reset!
      request = HTTP::Request.new("GET", "/param_prefix/test1/bar")
      route(request)
      Spy.param_prefix_was_called?.should be_true
    end
  end
end
