fs = require 'fs'

module.exports = class Utility
  @package: JSON.parse fs.readFileSync("package.json", 'utf8')
  @nameAndVersion: "#{@package.name} #{@package.version}"
