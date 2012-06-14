express = require 'express'
app     = express.createServer express.logger()
path    = require 'path'

port = process.env.port or 8012

app.configure () ->
  app.use express.static path.join(process.cwd(), process.argv[2])

console.log "ccloader test server listening on: #{port}"
console.log "please go to http://localhost:8012/"
app.listen port
