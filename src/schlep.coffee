HttpServer        = require "./http_server"
InputProcessor    = require "./input_processor"
Utility           = require "./utility"

console.log Utility.nameAndVersion

@httpServer       = new HttpServer
@inputProcessor   = new InputProcessor
