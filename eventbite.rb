require 'sinatra'
require 'oauth2'
require 'eventbrite-client'

redirect_uri = ENV['EVENTBRITE_REDIRECT']

client = OAuth2::Client.new(
  ENV['EVENTBRITE_KEY'],
  ENV['EVENTBRITE_SECRET'],
  :site => 'https://www.eventbrite.com'
)

get '/connect' do
  redirect client.auth_code.authorize_url(:redirect_uri => redirect_uri)
end

get '/authorised' do
  token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
  "try: " + url("/cal/#{token.token}")
end

get '/cal/:token' do
  ebc = EventbriteClient.new(:access_token => params[:token])
  ebc.user_list_tickets
end
