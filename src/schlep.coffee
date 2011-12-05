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

redis.on 'ready', ->
  console.log "Redis connected"

redis.on 'error', (err) ->
  console.log "Redis error: #{err}"
