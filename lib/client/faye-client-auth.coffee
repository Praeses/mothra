# The Auth 
# ---------
# The Auth  makes sure that the  communication going between the  server and the
# client  uses a  validated account.  It monitors  all traffic  and will  reject
# any  communiction that  does not  meet  the authentication  standards. If  the
# authentication is successful then the auth class will allow communication over
# the socket.

# Connecting the auth class to the window
window.Auth = class Auth
  constructor: ->
    # Standard bindings using underscore
    _.bindAll @, 'outgoing', 'success', 'errback'
  # Extension for faye.js.  This function will monitor all traffic  and send the
  # username and  password back  to the  server for  validation. If  the attempt
  # fails then it will try again. Otherwize it will enable the application
  outgoing: (message, callback) ->
    # Looking for the channel
    if message.channel != '/meta/subscribe'
      return callback message

    # We found the channel and are now in authentication mode
    @request_auth message, callback

  # Binding the auth class with the  given faye object, channel, and callback to
  # execute when there is data on the subscription
  bind: (@bayeux,@channel,@callback) ->
    @bayeux.addExtension @
    @connect_subscription()
 
  # This will do the actual connecting/re-connecting to the channel.
  connect_subscription: ->
    # If we already  have a subscription cancel  it ( remove the  listener ) and
    # create a new on
    @subscription?.cancel()
    @subscription = @bayeux.subscribe @channel, @callback
    # Hook  in callback  to  know  when the  subscription  has  connected or  be
    # rejected by the server
    @subscription.callback @success
    @subscription.errback @errback

  # Auth failure handles retrying the 
  errback: (err) ->
    # simple alert the user on the error
    alert err
    @connect_subscription()

  # `Unlock` the application
  success: ->
    $('.auth').hide()
    $('#create-equipment').show()
    # Grab the inventory  NOTE: Creating an event or callback  so that this does
    # not exists here would be good
    Inventory.fetch()

  # We are on the  correct channel and need to pass data to  the server. Here we
  # are waiting for an `enter` key to be pressed inorder to send the data to the
  # server
  request_auth: (message, callback) ->
    message.ext = {} unless message.ext

    $('#password').live 'keydown', (e) ->
      if e.keyCode == 13
        # We are ready to authenticate. Load up  the message and send it away to
        # the server
        message.ext.username = $('#username').val();
        message.ext.password = $('#password').val();
        callback message
