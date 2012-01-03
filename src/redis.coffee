redis = require 'redis'
url   = require 'url'

module.exports = class Redis
  constructor: ->
    # The Redis server is parsed from a URL
    redisUrl = process.env.REDIS_URL or process.env.REDISTOGO_URL

    if redisUrl
      parsedUrl  = url.parse redisUrl
      password   = parsedUrl.auth.split(":")[1]
      client = redis.createClient parsedUrl.port, parsedUrl.hostname, { auth_pass: true }
      client.auth password if password
    else
      client = redis.createClient()

    # Set up error logging
    client.on 'error', (err) -> console.dir err

    # Return the client back to the caller
    return client
