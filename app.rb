require 'open-uri'
require 'json'
require 'bundler/setup'
Bundler.require

configure do
  REDIS = if ENV["REDISTOGO_URL"]
    uri = URI.parse(ENV["REDISTOGO_URL"])
    Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  else
    Redis.new
  end
end

get '/' do
  haml :index
end

get '/:user/:repo' do
  @repo = params.values_at(:user, :repo).join("/")
  unless json = REDIS.get(@repo)
    url = "http://github.com/api/v2/json/repos/show/#{@repo}/network"
    json = open(url).read
    REDIS.set(@repo, json)
    REDIS.expire(@repo, 60 * 60)
  end
  @data = JSON.parse(json)
  haml :search
end
