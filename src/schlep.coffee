console.log "\nSchlep 0.0.0"

http     = require 'http'
redislib = require 'redis'
url      = require 'url'

# We need an HTTP server so that Heroku knows we're alive
http.createServer( (req, res) ->
  res.writeHead 200, {'Content-Type': 'text/plain'}
  res.end 'Schlep 0.0.0\n'
).listen process.env.PORT or 3000

# The Redis server is parsed from a URL
redis_url = process.env.REDIS_URL or process.env.REDISTOGO_URL

if redis_url
  redis_parsed_url = url.parse redis_url
  redis_password = redis_parsed_url.auth.split(":")[1]
  redis       = redislib.createClient redis_parsed_url.port, redis_parsed_url.hostname
  redis_block = redislib.createClient redis_parsed_url.port, redis_parsed_url.hostname
  redis.auth redis_password
else # If no Redis URL exists, we try to just connect to localhost
  redis       = redislib.createClient()
  redis_block = redislib.createClient()

redis.on 'error', (err) ->
  console.log "Redis error: #{err}"

# Once Redis is ready, we can start processing envelopes from the queue
redis.on 'ready', ->
  createProcessor()

# A processor does a blocking-left-pop on the schlep key. When a message is
# received and processed, it simply spawns another one of itself
createProcessor = ->
  redis_block.blpop "schlep", 0, (err, data) ->
    console.log err if err
    handleInput data[1]
    createProcessor()

handleInput = (data) ->
  # We validate the envelope against JSON before doing anything
  try
    envelope = JSON.parse(data)
  catch SyntaxError
    console.log "Invalid JSON: #{data}"
    return

  # If the validation fails, we just exit, since the validation error is
  # already output by the validtion function
  return unless validateEnvelope(envelope)

  # All messages are published to an event key for each type
  redis.publish "schlep:event:#{envelope.type}", JSON.stringify envelope

  # If the envelope type exists in schlep:queues, we push the envelope to a
  # worker queue for each type
  redis.sismember "schlep:queues", envelope.type, (err, sIsMember) ->
    console.log err if err
    if sIsMember
      redis.rpush "schlep:queue:#{envelope.type}", JSON.stringify envelope

  # Increment statistic keys
  for statistic in ["app", "host", "type"]
    redis.zincrby "schlep:statistic:#{statistic}", 1, envelope[statistic]

  # Output the envelope for debugging
  console.dir envelope

validateEnvelope = (envelope) ->
  requiredAttributes = {
    timestamp:  /^[0-9]*.?[0-9]*$/, # Numeric float
    app:        /[a-zA-Z0-9]*/, # Alphanumeric
    host:       /[a-zA-Z0-9]*/, # Alphanumeric
    type:       /[a-z_]*/, # Lowercase and underscores
    message:    null # We don't validate the actual message content
  }

  # For each top-level attribute, check that it exists, and that is passes regex validation
  for attribute, validation of requiredAttributes
    unless envelope.hasOwnProperty attribute
      console.log "Envelope missing #{attribute}"
      return false
    unless !validation or String(envelope[attribute]).match validation
      console.log "Validation for #{attribute} failed"
      return false

  # Validation is ok, return true
  true


