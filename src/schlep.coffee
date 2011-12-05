redislib = require 'redis'
url      = require 'url'

# Redis
redis_url = process.env.REDIS_URL or process.env.REDISTOGO_URL

if redis_url
  redis_parsed_url = url.parse process.env.REDISTOGO_URL
  redis_password = redis_url.auth.split(":")[1]
  redis = redislib.createClient redis_parsed_url.port, redis_parsed_url.hostname
  redis.auth redis_password
else
  redis = redislib.createClient()

redis.on 'error', (err) ->
  console.log "Redis error: #{err}"

redis.on 'ready', ->
  console.log "Ready"
  createProcessor()

createProcessor = ->
  console.log("New processor")
  redis.blpop "schlep", 0, (err, data) ->
    console.log(err) if err
    handleInput(data[1])
    createProcessor()

handleInput = (data) ->
  try
    envelope = JSON.parse(data)
  catch SyntaxError
    console.log "Invalid JSON: #{data}"
    return

  return unless validateEnvelope(envelope)

  redis.publish "schlep:event:#{envelope.type}", data

  for statistic in ["app", "host", "type"]
    redis.zincrby "schlep:statistic:#{statistic}", 1, envelope[statistic]

  console.dir envelope

validateEnvelope = (envelope) ->
  requiredAttributes = {
    timestamp:  /^[0-9]*.?[0-9]*$/,
    app:        /[a-zA-Z0-9]*/,
    host:       /[a-zA-Z0-9]*/,
    type:       /[a-z_]*/,
    message:    null
  }

  for attribute, validation of requiredAttributes
    unless envelope.hasOwnProperty attribute
      console.log "Envelope missing #{attribute}"
      return false
    unless no validation or String(envelope[attribute]).match validation
      console.log "Validation for #{attribute} failed"
      return false

  true


