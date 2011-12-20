Envelope = require "./envelope"
Redis    = require "./redis"
Mongo    = require "./mongo"

module.exports = class StorageProcessor
  constructor: ->
    @redis      = new Redis
    @redisBlock = new Redis
    @mongo      = new Mongo
    @wait()

  wait: ->
    @redisBlock.blpop "schlep:storage:queue", 0, (err, data) =>
      console.log err if err
      @handleData data[1]
      @wait()

  handleData: (data) ->
    envelope = new Envelope(data)

    # If the validation fails, we just exit, since the validation error is
    # already output by the validation function
    return unless envelope.isValid()

    @mongo.storeEnvelope envelope

