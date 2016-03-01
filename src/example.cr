require "./crouter"

class MyController
  private getter context, params
  def initialize(@context, @params)
  end

  def my_action
    # do something
    HTTP::Response.new(200, "hi there")
  end
end

class MyRouter < Crouter::Router
  get "/" do
    HTTP::Response.new(200, "hello world")
  end

  post "/path/with/:param" do
    HTTP::Response.new(200, "you passed #{params["param"]}")
  end

  get "/path/with(/optional(/:parts))" do
    HTTP::Response.new(200, "you passed #{params["parts"]? || "nothing"}")
  end

  put "/handle/with/controller", "MyController#my_action"

  group "/group" do
    put "/routes", "MyController#my_action"
    group "/or/even/:nest" do
      get "/them" do
        HTTP::Response.new(200, "with params! #{params["nest"]}")
      end
    end
  end
end

puts "Listening on http://127.0.0.1:8989"
HTTP::Server.new(8989, [HTTP::LogHandler.new, MyRouter.new]).listen
