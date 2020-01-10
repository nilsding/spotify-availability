#!/usr/bin/env ruby
# frozen_string_literal: true

###############################################################################
## Basic configuration

config = {
  client_id: ENV.fetch("SPOTIFY_CLIENT_ID"),
  client_secret: ENV.fetch("SPOTIFY_CLIENT_SECRET"),

  market: "AT"
}

require "bundler"
Bundler.setup :default

require "rspotify"
require "rspotify/oauth"
require "omniauth"
require "omniauth-oauth2"
require "webrick"
require "rack"

$stdout.sync = true

###############################################################################
## Authorisation with Spotify

# Workaround for `OAuth2::Error, invalid_grant: Invalid redirect URI'.  Sigh.
# Taken from: https://github.com/guilhermesad/rspotify/issues/87
module RSpotifyOmniauthHack
  def callback_url
    full_host + script_name + callback_path
  end
end
OmniAuth::Strategies::Spotify.include(RSpotifyOmniauthHack)

auth_url = "http://localhost:8080/auth/spotify"
puts "==> Please visit #{auth_url}"
3.times { puts }

$rack = Rack::Server.new(
  Port:   8080,
  server: "webrick",
  app: Rack::Builder.new do
    # OmniAuth requires a Rack session to be available
    use Rack::Session::Cookie, secret: "sjdklv"

    use OmniAuth::Builder do
      provider :spotify,
               *config.slice(:client_id, :client_secret).values,
               # We want to read our library (i.e. saved songs) and private playlists
               scope: "user-library-read playlist-read-private"
    end

    run(lambda do |env|
      case env["PATH_INFO"]
      when "/auth/spotify/callback"
        $omniauth_auth = env["omniauth.auth"]
        $rack.server.shutdown
        [200, { "Content-Type" => "text/html" },
         ["Code received.  Check your terminal."]]
      when "/auth/failure"
        [500, { "Content-Type" => "text/html" },
         [%(Auth failed.  Try it again: <a href="#{auth_url}">#{auth_url}</a>.)]]
      else
        [200, { "Content-Type" => "text/html" },
         [%(Please visit <a href="#{auth_url}">#{auth_url}</a>.)]]
      end
    end)
  end
)
$rack.start
3.times { puts }

me = RSpotify::User.new($omniauth_auth)

###############################################################################
## Fetching the song metadata and printing out some numbers

songs = []
offset = 0
page_size = 50
print "Fetching... "
loop do
  saved_tracks_part = me.saved_tracks(market: config[:market], limit: page_size, offset: offset)
  print "#{offset}... " unless offset.zero?
  break if saved_tracks_part.empty?

  songs.concat(saved_tracks_part)
  offset += page_size
rescue RestClient::BadGateway
  # Apparently Spotify's API returns a 502 Bad Gateway if there are no more songs available.
  # Fine, just rescue this error and move on ...
  puts "done!"
  break
end

puts "Found #{songs.count} songs."

grouped_songs = songs.group_by(&:is_playable)

puts "Playable songs: #{grouped_songs[true].count}"
puts "Unplayable songs: #{grouped_songs[false].count}"
print "That's "
print ((grouped_songs[false].count.to_f / songs.count) * 100).round(3)
puts "% unplayable songs!"

puts
puts "Unplayable:"
grouped_songs[false].each_with_index do |song, index|
  artists = song.artists.map(&:name).join(", ")
  restrictions = song.artists.map(&:name).join(", ")
  puts "#{index + 1}.\t#{artists} - #{song.name}"
end
