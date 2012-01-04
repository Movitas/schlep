EventEmitter = require('events').EventEmitter

mongodb = require 'mongodb'
url     = require 'url'

module.exports = class Mongo extends EventEmitter
  constructor: ->
    @database = "schlep"
    @hostname = "127.0.0.1"
    @port = 27017
    @url = process.env.MONGO_URL or process.env.MONGODB_URL or process.env.MONGOHQ_URL

    if @url
      @parsedUrl = url.parse @url
      @auth     = @parsedUrl.auth.split(":")        if @parsedUrl.auth
      @database = @parsedUrl.pathname.split("/")[1] if @parsedUrl.pathname
      @hostname = @parsedUrl.hostname
      @port     = @parsedUrl.port                   if @parsedUrl.port

    @options = {
      auto_reconnect: true
    }

    @client = new mongodb.Db @database, (new mongodb.Server @hostname, @port, @options)

    @client.open (error, db) =>
      if error
        console.log error
      else
        @db = db

        if @auth
          @db.authenticate @auth[0], @auth[1], (error) =>
            console.log error if error
            @emit "ready"
        else
          @emit "ready"

  storeEnvelope: (envelope) ->
    @db.collection envelope.sanitized_type, (error, collection) ->
      if error
        console.log error
      else
        collection.save envelope.envelope, (error, documents) ->
          if error
            console.log error
