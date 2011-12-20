HttpServer        = require "./http_server"
InputProcessor    = require "./input_processor"
StorageProcessor  = require "./storage_processor"
Utility           = require "./utility"

console.log Utility.nameAndVersion

@httpServer       = new HttpServer
@inputProcessor   = new InputProcessor
@storageProcessor = new StorageProcessor
