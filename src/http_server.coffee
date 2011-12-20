http = require 'http'
Utility = require "./utility"

module.exports = class HttpServer
  constructor: ->
    # We need an HTTP server so that Heroku knows we're alive
    http.createServer( (req, res) ->
      res.writeHead 200, {'Content-Type': 'text/plain'}
      res.end "#{Utility.nameAndVersion}\n"
    ).listen process.env.PORT or 3000
