(function() {
  var redis, redis_parsed_url, redis_password, redis_url, redislib, url;
  redislib = require('redis');
  url = require('url');
  redis_url = process.env.REDIS_URL || process.env.REDISTOGO_URL;
  if (redis_url) {
    redis_parsed_url = url.parse(process.env.REDISTOGO_URL);
    redis_password = redis_url.auth.split(":")[1];
    redis = redislib.createClient(redis_parsed_url.port, redis_parsed_url.hostname);
    redis.auth(redis_password);
  } else {
    redis = redislib.createClient();
  }
  redis.on('ready', function() {
    return console.log("Redis connected");
  });
  redis.on('error', function(err) {
    return console.log("Redis error: " + err);
  });
}).call(this);
