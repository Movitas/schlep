Envelope = require "./envelope"
Redis    = require "./redis"

module.exports = class InputProcessor
  constructor: ->
    @redis      = new Redis
    @redisBlock = new Redis
    @wait()

  wait: ->
    @redisBlock.blpop "schlep", 0, (err, data) =>
      console.log err if err
      @handleData data[1]
      @wait()

  handleData: (data) ->
    envelope = new Envelope(data)

    # If the validation fails, we just exit, since the validation error is
    # already output by the validation function
    return unless envelope.isValid()

    @publish  envelope
    @queue    envelope
    @store    envelope
    @record   envelope

  # All messages are published to an event key for each type
  publish: (envelope) ->
    @redis.publish "schlep:event:#{envelope.type}", envelope.json

  # If the envelope type exists in schlep:queues, we push the envelope to a
  # worker queue for each type
  queue: (envelope) ->
    @redis.sismember "schlep:queues", envelope.type, (err, sIsMember) =>
     console.log err if err
     if sIsMember
       @redis.rpush "schlep:queue:#{envelope.type}", envelope.json

  # If the envelope type exists in schlep:storage:types, we push the envelope
  # to a the storage queue
  store: (envelope) ->
    @redis.sismember "schlep:storage:types", envelope.type, (err, sIsMember) =>
       console.log err if err
       if sIsMember
         @redis.rpush "schlep:storage:queue", envelope.json

  # We record various statistics for each envelope processed
  record: (envelope) ->
    # Increment the processed counter
    @redis.zincrby "schlep:statistics", 1, "total"

    # Increment statistic keys
    for statistic in ["app", "host", "type"]
      @redis.zincrby "schlep:statistic:#{statistic}", 1, envelope[statistic]
