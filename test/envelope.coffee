Envelope = require "../src/envelope"

testEnvelope = (field, value) ->
  e = {
    timestamp:  1234567890.12345,
    app:        "awesome_app",
    host:       "awesome_host",
    type:       "awesome_type",
    message:    "awesome message"
  }
  e[field] = value if field and value
  new Envelope(JSON.stringify e)

exports.timestamp =
  "should return the timestamp": (test) ->
    test.equal testEnvelope().timestamp, 1234567890.12345
    test.done()

  "should allow numeric timestamps": (test) ->
    e = testEnvelope('timestamp', 1234567890)
    test.ok e.isValid()
    test.done()

  "should not allow non-numeric timestamps": (test) ->
    e = testEnvelope('timestamp', "string")
    test.ok !e.isValid()
    test.done()

exports.app =
  "should return the app": (test) ->
    test.equal testEnvelope().app, "awesome_app"
    test.done()

exports.host =
  "should return the host": (test) ->
    test.equal testEnvelope().host, "awesome_host"
    test.done()

exports.type =
  "should return the type": (test) ->
    test.equal testEnvelope().type, "awesome_type"
    test.done()

exports.message =
  "should return the message": (test) ->
    test.equal testEnvelope().message, "awesome message"
    test.done()

exports.sanitized_app =
  "should lowercase the app": (test) ->
    test.equal testEnvelope('app', "AbCdE").sanitized_app, "abcde"
    test.done()

  "should replace spaces and special characters with underscores": (test) ->
    test.equal testEnvelope('app', "awesome app! right?").sanitized_app, "awesome_app_right"
    test.done()