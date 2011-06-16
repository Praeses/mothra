EventEmitter = require( 'events' ).EventEmitter

Sync = {}

class Sync extends EventEmitter

  constructor: ->
    redis  = require('redis')
    client = redis.createClient()

    @on 'create', @create

  incomming: (message, callback) ->
    # Don't use the message if we don't like it
    regex = /\/models\/(\w+)/
    unless regex.test message.channel
      return callback message

    # Here is where we will persist the data
    message.model # Collection or Model
    message.method # What to do
    
    @emit message.method, regex.exec( message.channel )[0], message.model

    callback message

  create: (base_key, model) ->
    # Create
    console.log( base_key )
    console.log( model )
   


exports.Sync = Sync
