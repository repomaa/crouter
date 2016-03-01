require "../spec_helper"

call_spy Spy, foo, bar, first_block, second_block, prefix, without_prefix, sub_prefix, param_prefix, trailing, non_trailing

class TestController
  private getter context, params
  def initialize(@context, @params)
  end

  def foo
    Spy.foo
    params["bar"].should eq("bar")
  end

  def bar
    Spy.bar
    params["bar"]?.should eq("bar")
  end
end

class TestRouter < Crouter::Router
  get "/foo(/:bar)", "TestController#foo"
  post "/foo(/:bar)", "TestController#bar"

  post "/foo/foo" do
    Spy.first_block
  end

  post "/bar" do
    Spy.second_block
    params["test"].should eq("foobar")
  end

  group "/prefix" do
    get "/foo(/:bar)" do
      Spy.prefix
      params["bar"].should eq("foobar")
    end

    group "/sub_prefix" do
      get "/foo" do
        Spy.sub_prefix
      end
    end
  end

  group "/param_prefix/:foo" do
    get "/bar" do
      Spy.param_prefix
      params["foo"].should eq("test1")
    end
  end

  get "/without/prefix" do
    Spy.without_prefix
  end

  get "/return.:format" do
    case params["format"]
    when "json" then context.response.print %({"test":"foobar"})
    when "xml" then context.response.print %(<?xml version="1.0" encoding="utf-8"?><test>foobar</test>)
    else 
      context.response.status_code = 400
      context.response.print "invalid format"
    end
  end

  get "/trailing/" do
    Spy.trailing
  end

  get "/non-trailing" do
    Spy.non_trailing
  end
end

def route(method, path, router_mount_point = "")
  io = MemoryIO.new
  request = HTTP::Request.new(method, path)
  response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, response)
  TestRouter.new(router_mount_point).call(context)
  response.flush
  { response, io.to_s }
end

describe Crouter::Router do
  describe ".route" do
    it "matches a route for the context method and path and calls its action" do
      Spy.reset!
      route("GET", "/foo/bar")
      Spy.foo_was_called?.should be_true
      Spy.bar_was_called?.should be_false

      Spy.reset!
      route("POST", "/foo/bar")
      Spy.bar_was_called?.should be_true
      Spy.foo_was_called?.should be_false
    end

    it "favors static routes and calls only one route" do
      Spy.reset!
      route("POST", "/foo/foo")
      Spy.first_block_was_called?.should be_true
      Spy.bar_was_called?.should be_false
    end

    it "calls blocks" do
      Spy.reset!
      route("POST", "/bar?test=foobar")
      Spy.second_block_was_called?.should be_true
    end

    it "sets status code 404 if no route matches" do
      response, raw = route("GET", "/non-existing/route")
      response.status_code.should eq(404)
    end

    it "writes to the response body" do
      response, raw = route("GET", "/return.json")
      raw.should match(/\{"test":"foobar"\}/)
    end

    it "matches trailing / variants of a route and vice versa" do
      Spy.reset!
      route("GET", "/trailing")
      Spy.trailing_was_called?.should be_true

      Spy.reset!
      route("GET", "/non-trailing/")
      Spy.non_trailing_was_called?.should be_true
    end
  end

  describe "group" do
    it "groups underlying routes by preit a given prefix" do
      Spy.reset!
      route("GET", "/prefix/foo/foobar")
      Spy.prefix_was_called?.should be_true
    end

    it "it restores the prefix after the block" do
      Spy.reset!
      route("GET", "/without/prefix")
      Spy.without_prefix_was_called?.should be_true
    end

    it "it supports nesting" do
      Spy.reset!
      route("GET", "/prefix/sub_prefix/foo")
      Spy.sub_prefix_was_called?.should be_true
    end

    it "it supports params in group prefix" do
      Spy.reset!
      route("GET", "/param_prefix/test1/bar")
      Spy.param_prefix_was_called?.should be_true
    end
  end

  describe ".new" do
    it "supports mountpoints" do
      Spy.reset!
      route("GET", "/mountpoint/foo/bar", "/mountpoint")
      Spy.foo_was_called?.should be_true
    end
  end
end
