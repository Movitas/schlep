http     = require 'http'
fs       = require 'fs'
redislib = require 'redis'
url      = require 'url'

package = JSON.parse(fs.readFileSync("package.json", 'utf8'))

console.log "#{package.name} #{package.version}"

# We need an HTTP server so that Heroku knows we're alive
http.createServer( (req, res) ->
  res.writeHead 200, {'Content-Type': 'text/plain'}
  res.end "#{package.name} #{package.version}\n"
).listen process.env.PORT or 3000

# The Redis server is parsed from a URL
redis_url = process.env.REDIS_URL or process.env.REDISTOGO_URL

# We create a redis client for non-blocking commands,
# and others for blocking operations
if redis_url
  # If a redis_url exists, we parse the URL and connect/auth from each Redis client
  redis_parsed_url  = url.parse redis_url
  redis_password    = redis_parsed_url.auth.split(":")[1]

  redis         = redislib.createClient redis_parsed_url.port, redis_parsed_url.hostname, { auth_pass: true }
  redis_schlep  = redislib.createClient redis_parsed_url.port, redis_parsed_url.hostname, { auth_pass: true }
  redis_store   = redislib.createClient redis_parsed_url.port, redis_parsed_url.hostname, { auth_pass: true }

  redis.auth        redis_password
  redis_schlep.auth redis_password
  redis_store.auth  redis_password
else
  # If no Redis URL exists, we try to just connect each Redis client to localhost
  redis         = redislib.createClient()
  redis_schlep  = redislib.createClient()
  redis_store   = redislib.createClient()

# Create error callbacks for each Redis client
redis.on        'error', (err) -> console.log "redis        error: #{err}"
redis_schlep.on 'error', (err) -> console.log "redis_schlep error: #{err}"
redis_store.on  'error', (err) -> console.log "redis_store  error: #{err}"

# Create processed counter for info output
processed = 0

redis.on 'ready', ->
  # Once Redis is ready, we can start processing envelopes from the queue
  createSchlepProcessor()
  createStorageProcessor()

  # Output the processed counter and queue length, but only if we did work in the past second
  setInterval ->
    redis.llen "schlep", (err, data) ->
      console.log err if err
      console.log "#{processed}/sec, #{data} queued" if processed > 0
      processed = 0
  , 1000

# Processors do a blocking-left-pop on a key. When a message is received and
# processed, it simply spawns another one of itself.

# A Schlep processor handles all messages on the input queue.
createSchlepProcessor = ->
  redis_schlep.blpop "schlep", 0, (err, data) ->
    console.log err if err
    handleEnvelope data[1]
    createSchlepProcessor()

# A Storage processor stores events in MongoDB
createStorageProcessor = ->
  redis_store.blpop "schlep:storage:queue", 0, (err, data) ->
    console.log err if err
    storeEnvelope data[1]
    createStorageProcessor()

handleEnvelope = (data) ->
  # We validate the envelope against JSON before doing anything
  try
    envelope = JSON.parse(data)
  catch SyntaxError
    console.log "Invalid JSON: #{data}"
    return

  # If the validation fails, we just exit, since the validation error is
  # already output by the validation function
  return unless validateEnvelope(envelope)

  # All messages are published to an event key for each type
  redis.publish "schlep:event:#{envelope.type}", JSON.stringify envelope

  # If the envelope type exists in schlep:queues, we push the envelope to a
  # worker queue for each type
  redis.sismember "schlep:queues", envelope.type, (err, sIsMember) ->
    console.log err if err
    if sIsMember
      redis.rpush "schlep:queue:#{envelope.type}", JSON.stringify envelope

  # If the envelope type exists in schlep:storage:types, we push the envelope
  # to a the storage queue
  redis.sismember "schlep:storage:types", envelope.type, (err, sIsMember) ->
    console.log err if err
    if sIsMember
      redis.rpush "schlep:storage:queue", JSON.stringify envelope

  # Increment the processed counter
  processed += 1
  redis.zincrby "schlep:statistics", 1, "total"

  # Increment statistic keys
  for statistic in ["app", "host", "type"]
    redis.zincrby "schlep:statistic:#{statistic}", 1, envelope[statistic]

  # Output the envelope for debugging
  # console.dir envelope

validateEnvelope = (envelope) ->
  requiredAttributes = {
    timestamp:  /^[0-9]*.?[0-9]*$/, # Numeric float
    app:        /[a-zA-Z0-9]*/,     # Alphanumeric
    host:       /[a-zA-Z0-9]*/,     # Alphanumeric
    type:       /[a-z_]*/,          # Lowercase and underscores
    message:    null                # We don't validate the actual message content
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

storeEnvelope = (envelope) ->
  console.dir (envelope)