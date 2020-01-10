# spotify-availability

Prints out how many songs of your ~~Liked~~ Saved Songs library are not playable
in a given Spotify market.

## Usage 

1. Create a [Spotify application][dashboard]
2. Add the redirect URI `http://localhost:8080/auth/spotify/callback` to the
   settings of it
3. Run `bundle install` to install dependencies
4. Optionally set the market in the configuration hash at the top of
   `spotify-availability.rb`.  By default it's set to `AT` (Austria), since
   that's where I'm from.
5. Run it: `SPOTIFY_CLIENT_ID=clientId SPOTIFY_CLIENT_SECRET=clientSecret bundle
   exec ruby ./spotify-availability.rb`
6. Follow the instructions in your terminal

Eventually, something similar to this will be printed to the console:

```
Found 4718 songs.
Playable songs: 4641
Unplayable songs: 77
That's 1.632% unplayable songs!

Unplayable:
1.      EAV - Im Himmel ist die Hölle los
2.      Anders Enger Jensen - 8-Bit Keys Theme - Remix
3.      Ottawan - D.I.S.C.O.
[... many more songs omitted ...]
```

[dashboard]: https://developer.spotify.com/dashboard/applications
