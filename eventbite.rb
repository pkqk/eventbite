require 'sinatra'
require 'oauth2'
require 'eventbrite-client'

redirect_uri = ENV['EVENTBRITE_REDIRECT']

client = OAuth2::Client.new(
  ENV['EVENTBRITE_KEY'],
  ENV['EVENTBRITE_SECRET'],
  :site => 'https://www.eventbrite.com'
)

get '/favicon.ico' do
  410
end

get '/' do
  redirect client.auth_code.authorize_url(:redirect_uri => redirect_uri)
end

get '/authorised' do
  token = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
  erb :show, :locals => { :ical => url("/cal/#{token.token}") }
end

get '/cal/:token' do
  ebc = EventbriteClient.new(:access_token => params[:token])

  tickets = begin
    r = ebc.user_list_tickets
    r['user_tickets'][1]['orders'].map{|o| o['order']['event'] }
  rescue
    []
  end

  content_type 'text/calendar'
  [200, ["BEGIN:VCALENDAR", "VERSION:2.0", "CALNAME:Eventbrite", *vevents(tickets), "END:VCALENDAR"].join("\n")]
end

def vevents(orders)
  orders.map { |order| vevent(order) }
end

def vevent(event)
  id = event['id']
  title = event['title']
  url = event['url']
  start_date = ical_time(Time.parse(event['start_date']))
  end_date = ical_time(Time.parse(event['end_date']))
  [
    "BEGIN:VEVENT",
    "UID:#{id}@eventbrite.com",
    "DTSTAMP:#{start_date}",
    "DTSTART:#{start_date}",
    "DTEND:#{end_date}",
    "SUMMARY:#{title}",
    "URL:#{url}",
    "END:VEVENT"
  ]
end

def ical_time(time)
  time.utc.iso8601.gsub(/[:-]/,'')
end
