#! /usr/bin/ruby
# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'cgi'

require 'bloomrb'
require 'json'
require 'redis'
require 'sinatra'
require 'sinatra/json'

# Sinatra Config
set :public_folder, File.dirname(__FILE__) + '/static'
set :erb, format: :html5

# Helpers
helpers Sinatra::JSON

# Add #to_human to Integer class
class Integer
  def to_human
    {
      'B'  => 1024,
      'KB' => 1024 * 1024,
      'MB' => 1024 * 1024 * 1024,
      'GB' => 1024 * 1024 * 1024 * 1024,
      'TB' => 1024 * 1024 * 1024 * 1024 * 1024
    }.each_pair do |e, s|
      return "#{(to_f / (s / 1024)).round(2)}#{e}" if self < s
    end
  end
end

@redis_client = Redis.new

def bloom_redis
  @redis_client ||= Redis.new
end

def all_servers
  bloom_redis.hgetall 'blooming-servers' rescue {}
end

# root route
get '/' do
  @servers = all_servers
  erb :index
end

get '/server/details' do
  @server = bloom_redis.hget 'blooming-servers', params['host']
  bloomd =  Bloomrb.new CGI.unescape(params['host'])
  @details = bloomd.list rescue []
  erb :server
end

post '/server' do
  bloom_redis.hset 'blooming-servers', params['host'], params['name']
  redirect "server/details?host=#{CGI.escape params['host']}"
end

get '/server/remove' do
  bloom_redis.hdel 'blooming-servers', params['host']
  redirect '/'
end
