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
  @data = fetch("http://github.com/api/v2/json/repos/show/#{@repo}/network")
  haml :search
end

get '/:repo' do
  @repo = params["repo"]
  data = fetch("http://github.com/api/v2/json/repos/search/#{@repo}")
  if data["repositories"][0]
    redirect "/#{data["repositories"][0].values_at("owner", "name").join("/")}"
  else
    haml :repository_not_found
  end
end

def fetch(url, expire = 60 * 60)
  unless json = REDIS.get(url)
    json = open(url).read
    REDIS.set(url, json)
    REDIS.expire(url, 60 * 60)
  end
  JSON.parse(json)
end
