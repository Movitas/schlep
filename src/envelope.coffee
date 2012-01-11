module.exports = class Envelope
  REQUIRED_ATTRIBUTES: {
    timestamp:  /^[0-9]*.?[0-9]*$/, # Numeric float
    app:        /[a-zA-Z0-9]*/,     # Alphanumeric
    host:       /[a-zA-Z0-9]*/,     # Alphanumeric
    type:       /[a-z_]*/,          # Lowercase and underscores
    message:    null                # We don't validate the actual message content
  }

  constructor: (data) ->
    @data = data

    # We validate the envelope against JSON before doing anything
    try
      @envelope = JSON.parse @data
      @validJson = true
    catch SyntaxError
      console.log "Invalid JSON: #{data}"
      return

    @json = JSON.stringify @envelope

    # Define getters for each attribute, to avoid Envelope.envelope.type
    for key, value of @REQUIRED_ATTRIBUTES
      this[key] = @envelope[key]

    @sanitized_app = @app
    @sanitized_app = @sanitized_app.replace /[^\w\n]+/g, "_" # Replace special characters with underscores
    @sanitized_app = @sanitized_app.replace /^_|_$/g, "" # Remove leading and trailing underscores
    @sanitized_app = @sanitized_app.toLowerCase()

  isValid: ->
    # Don't bother validating if we've already determined the JSON is invalid
    return false unless @validJson

    # For each top-level attribute, check that it exists, and that is passes
    # regex validation
    for attribute, validation of @REQUIRED_ATTRIBUTES
      unless @envelope.hasOwnProperty attribute
        console.log "Envelope missing #{attribute}"
        return false
      unless !validation or String(@envelope[attribute]).match validation
        console.log "Validation for #{attribute} failed: \"#{@envelope[attribute]}\""
        return false

    # Validation is ok, return true
    @valid = true
