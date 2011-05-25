http = require 'http'
Faye = require 'faye'
url  = require 'url'
path = require 'path'
fs   = require 'fs'

faye_server = new Faye.NodeAdapter { mount : '/faye', engine : { type :'redis' } }

server = http.createServer (request, response) ->
  uri = url.parse( request.url ).pathname
  uri = 'index' if uri == '/'
  uri += '.html' unless /\.(js|css|coffee)$/.test uri
  uri = 'public/' + uri
  filename = path.join(process.cwd(), uri)
  
  render_file = (exists) ->
    if(!exists) 
      response.writeHead(404, {"Content-Type": "text/plain"})
      response.end("404 Not Found\n")
      return

    out_file = (err,file) ->
      if(err) 
        response.writeHead(500, {"Content-Type": "text/plain"})
        response.end(err + "\n")
        return


      response.writeHead(200)
      response.end(file, "binary")

    fs.readFile(filename, "binary", out_file )
    
  path.exists(filename, render_file)

faye_server.attach server 
server.listen 1337

out_message = (messages) ->
  console.log messages.text

faye_server.getClient().subscribe '/messages', out_message

push = -> 
  faye_server.getClient().publish '/messages' , { text: 'w00t' }
  console.log 'pushing'

#setInterval push, 5000
console.log 'Server running at http://127.0.0.1:1337/'
