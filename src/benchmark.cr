require "./crouter"
require "benchmark"

{% for i in 5..8 %}
  {% route_count = 2 ** i %}
  class MyRouter{{route_count}} < Crouter::Router
    \{% for i in 0..{{route_count}} %}
      get "/route_{{i}}(/:param1(/:param2))" do
        param1, param2 = { params["param1"]?, params["param2"]? }.map { |param| param || "nothing" }
        return HTTP::Response.new(200, "hi from route_{{i}}, you passed #{param1} and #{param2}")
      end
    \{% end %}
  end
{% end %}

def url_gen(max_index, port)
  "http://127.0.0.1:#{port}/route_#{rand(0..max_index)}#{"/foo#{"/bar" if rand < 5}" if rand < 5}"
end

servers = [] of Process
servers << fork do
  HTTP::Server.new(10_000) { |context| HTTP::Response.new(200, "raw throughput") }.listen
end

{% for i in 5..8 %}
  {% route_count = 2 ** i %}
  {% port = 10_001 + i - 5 %}
  servers << fork do
    HTTP::Server.new({{port}}, MyRouter{{route_count.id}}.new).listen
  end
{% end %}

Benchmark.ips do |bm|
  puts "contexts per second"

  bm.report("without router (raw server throughput)") do
    response = HTTP::Client.get(url_gen(10_000, 10_000))
    response.body
  end

  {% for i in 5..8 %}
    {% route_count = 2 ** i %}
    {% port = 10_001 + i - 5 %}

    bm.report("through router with {{route_count}} routes") do
      response = HTTP::Client.get(url_gen({{route_count}}, {{ port }}))
      response.body
    end
  {% end %}
end

servers.each { |process| process.kill(Signal::TERM) }
