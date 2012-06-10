express = require 'express'
app     = express.createServer express.logger()
path    = require 'path'

app.configure () ->
  app.use express.static path.join(process.cwd(), process.argv[2])

app.listen 8008
