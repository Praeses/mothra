class ActiveDirectory

  constructor: ->
    # https://github.com/joewalnes/node-ldapauth 
    @ldapauth = require './ldapauth'

  bind: (bayeux) ->
    @bayeux = bayeux
    @bayeux.addExtension @

  incoming: (message, callback) ->

    if message.channel != '/meta/subscribe'
      return callback message

    username = ( message.ext and "intel\\#{ message.ext.username }" )
    password = ( message.ext and message.ext.password ) 

    if username && password
      @ldapauth.authenticate 'praeses.com', 389, username, password, ( err, result ) ->
        if err
          message.error = err
        else if !result
          message.error = 'Invalid stuff dude'
    else
      message.error = 'need username and password'
      

    callback message

exports.ActiveDirectory = ActiveDirectory
