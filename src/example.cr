require "./crouter"

class MyController
  private getter context : HTTP::Server::Context, params : HTTP::Params

  def initialize(@context, @params)
  end

  def my_action
    # do something
    context.response << "hi there"
  end
end

class MyRouter < Crouter::Router
  get "/" do
    context.response << "hello world"
  end

  post "/path/with/:param" do
    context.response << "you passed #{params["param"]}"
  end

  get "/path/with(/optional(/:parts))" do
    context.response << "you passed #{params["parts"]? || "nothing"}"
  end

  put "/handle/with/controller", "MyController#my_action"

  group "/group" do
    put "/routes", "MyController#my_action"
    group "/or/even/:nest" do
      get "/them" do
        context.response << "with params! #{params["nest"]}"
      end
    end
  end
end

puts "Listening on http://127.0.0.1:8989"
HTTP::Server.new(8989, [HTTP::LogHandler.new, MyRouter.new]).listen
