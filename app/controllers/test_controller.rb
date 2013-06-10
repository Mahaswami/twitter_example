require 'oauth'

class TestController < ApplicationController

  CONSUMER_KEY = 'oURAW1AeEqZT2i9DyqFYQ'
  CONSUMER_TOKEN = ''

  def index
  end
  
  def authorize
    consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_TOKEN, :site => "https://api.twitter.com")  
    request_token = consumer.get_request_token pin_auth_parameters
    session[:twitter_request_secret] = request_token.secret
    session[:twitter_request_token] = request_token.token
    url = generate_authorize_url(consumer, request_token)
    redirect_to url
  end
  
  def return
    consumer = OAuth::Consumer.new(CONSUMER_KEY, CONSUMER_TOKEN, :site => "https://api.twitter.com")  
    request_token = OAuth::RequestToken.new(consumer, session[:twitter_request_token], session[:twitter_request_secret])
    access_token = request_token.get_access_token :oauth_verifier => params["oauth_verifier"] 
    session[:twitter_access_secret] = access_token.secret
    session[:twitter_access_token] = access_token.token
    redirect_to :root
  end
  
  def post
    Twitter.configure do |config|
      config.consumer_key = CONSUMER_KEY
      config.consumer_secret = CONSUMER_TOKEN
    end  
    client = Twitter::Client.new(
      :oauth_token => session[:twitter_access_token],
      :oauth_token_secret => session[:twitter_access_secret]
    )  
    Thread.new{client.update(params[:update])}  
    redirect_to :root
  end
  
  def forget_token
    session[:twitter_access_token] = nil
    session[:twitter_access_secret] = nil
    redirect_to :root
  end  
  
  protected
  
  def generate_authorize_url(consumer, request_token)
    request = consumer.create_signed_request(:get, consumer.authorize_path, request_token, pin_auth_parameters)
    params = request['Authorization'].sub(/^OAuth\s+/, '').split(/,\s+/).map do |param|
      key, value = param.split('=')
      value =~ /"(.*?)"/
      "#{key}=#{CGI::escape($1)}"
    end.join('&')
    "https://api.twitter.com#{request.path}?#{params}"
  end    
  
  def pin_auth_parameters
    {:oauth_callback => 'http://127.0.0.1:3000/test/return'}
  end
  
end