
# Exported for both CommonJS and the browser
if exports?
  _ = require('underscore')._
  Backbone = require('backbone')
  Store = module.exports = {}
else
  Store = this.Store = {}

Store = this.Store = (options) ->
  @options = options or {}

  @host = options.host or window.locahost.hostname
  @port = options.port or 8585

  @handlers = {}
  @state = 'disconected'
  @meta = @options.meta

  @bayeux = new Faye.Client @options.bayeux or '/faye'

  @bayeux.publish '/meta', this.meta
  true
