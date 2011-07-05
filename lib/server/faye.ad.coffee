# The Active Directory
# --------------------
# Authentication has been done many times.  There are many ways of doing it.  We have
# AD at our disposal so we are going to use it.  the `ActiveDirectory` class will 
# manage communication to our AD instance.  NOTE: we need to put the settings in a config
# file so that the details to connect to our AD do not exists in code.


class ActiveDirectory

  constructor: ->
    # https://github.com/joewalnes/node-ldapauth 
    @ldapauth = require './ldapauth'

  # Take in a `faye` object and add `this` as an extention
  bind: (bayeux) ->
    @bayeux = bayeux
    @bayeux.addExtension @

  # Listing to  all incomming messages and  intercepting the `\/meta\/subscribe`
  # channel. This channel  is the one that  will need to be blocked  if the auth
  # fails.
  incoming: (message, callback) ->

    # Checking the message
    if message.channel != '/meta/subscribe'
      return callback message

    # For our  AD auth we need  to pass in the  domain. If the user  typed it in
    # then we want to remove what they typed so that we do not duplicate it.
    username = "intel\\#{ message.ext?.username.replace( /^intel\\/i, '' ) }" 
    password = message.ext?.password 

    # By adding  an object  to the  error property  of the  message we  can stop
    # communication on the socket.
    if username && password
      @ldapauth.authenticate 'praeses.com', 389, username, password, ( err, result ) ->
        if err
          message.error = err
        else if !result
          message.error = 'Invalid stuff dude'
    else
      message.error = 'need username and password'
  
    # Again passing through the callback chain
    callback message

# Exposing the `ActiveDirectory` class to the outside world
exports.ActiveDirectory = ActiveDirectory