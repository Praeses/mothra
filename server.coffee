# MOTHRA!!!!
# ==========
# After many years terrorizing people, destroying buildings and cities, battling
# the  greatest monsters  of all  time,  Mothra decided  to retire  and take  it
# easy......as an inventory specialist

# Requiring the libs we are going to use for the app. To install theses libs run
# `npm install` and they will be installed using the package.json. Faye is a lib
# that will manage  communiction between the server and the  client. It will use
# websockets when it can and then fail back to long polling.  `node-static` will
# handle the static assets of the application (css|js|html).
http            = require 'http'
Faye            = require 'faye'
Static          = require 'node-static'
RedisSync       = require './lib/server/backbone-faye-server-store'
ActiveDirectory = require './lib/server/faye.ad'

# Starting up our  servers. There will be  two. The first is for  the web socket
# layer. It  will be  running under  the location `'/faye'`.  The second  is the
# static file server. This will server up our assets (css|js|html).
bayeux      = new Faye.NodeAdapter { mount : '/faye' }
static_file = new Static.Server './public'


# This is the http node.js server. Here  is where we will attach the static file
# server.
server = http.createServer (request, response) ->
  request.addListener 'end', -> static_file.serve request, response

# Now we are creating  an instance of the `Sync` class. This  will manage all of
# our **CRUD** communication.  It will intercept all messages from  the client (
# and server ) and look for a pattern to persist to the database. To enable this
# lib we need to bind it to `faye`
sync = new RedisSync.Sync
sync.bind bayeux

# Authentication for this  application will be managed by our  AD. Just like the
# `Sync` class above we will need to bind this to `faye` to enable it.
ad = new ActiveDirectory.ActiveDirectory
ad.bind bayeux

# Attaching the faye server to the http serve
bayeux.attach server 
# Starting the http server on port 1337
server.listen 1337

# Let the user know what is going on
console.log 'Server running at http://127.0.0.1:1337/'
