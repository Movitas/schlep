(function() {
  var createProcessor, handleInput, redis, redis_parsed_url, redis_password, redis_url, redislib, url, validateEnvelope;
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
  redis.on('error', function(err) {
    return console.log("Redis error: " + err);
  });
  redis.on('ready', function() {
    console.log("Ready");
    return createProcessor();
  });
  createProcessor = function() {
    console.log("New processor");
    return redis.blpop("schlep", 0, function(err, data) {
      if (err) {
        console.log(err);
      }
      handleInput(data[1]);
      return createProcessor();
    });
  };
  handleInput = function(data) {
    var envelope, statistic, _i, _len, _ref;
    try {
      envelope = JSON.parse(data);
    } catch (SyntaxError) {
      console.log("Invalid JSON: " + data);
      return;
    }
    if (!validateEnvelope(envelope)) {
      return;
    }
    redis.publish("schlep:event:" + envelope.type, data);
    _ref = ["app", "host", "type"];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      statistic = _ref[_i];
      redis.zincrby("schlep:statistic:" + statistic, 1, envelope[statistic]);
    }
    return console.dir(envelope);
  };
  validateEnvelope = function(envelope) {
    var attribute, requiredAttributes, validation;
    requiredAttributes = {
      timestamp: /^[0-9]*.?[0-9]*$/,
      app: /[a-zA-Z0-9]*/,
      host: /[a-zA-Z0-9]*/,
      type: /[a-z_]*/,
      message: null
    };
    for (attribute in requiredAttributes) {
      validation = requiredAttributes[attribute];
      if (!envelope.hasOwnProperty(attribute)) {
        console.log("Envelope missing " + attribute);
        return false;
      }
      if (!(!validation || envelope[attribute].toString().match(validation))) {
        console.log("Validation for " + attribute + " failed");
        return false;
      }
    }
    return true;
  };
}).call(this);
