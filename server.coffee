# Init vars
http   = require 'http'
Faye   = require 'faye'
Static = require 'node-static'

# Init Servers
bayeux      = new Faye.NodeAdapter { mount : '/faye', engine : { type :'redis' } }
static_file = new Static.Server './public'

server = http.createServer (request, response) ->
  request.addListener 'end', ->
    static_file.serve request, response

bayeux.attach server 
server.listen 1337

out_message = (messages) ->
  console.log messages.text

bayeux.getClient().subscribe '/messages', out_message

push = -> 
  bayeux.getClient().publish '/messages' , { text: 'w00t' }
  console.log 'pushing'

#setInterval push, 5000
console.log 'Server running at http://127.0.0.1:1337/'
