const express = require('express')
const cors = require('cors')
const morgan = require('morgan')
const http = require('http')
const bodyParser = require('body-parser')
const {sequelize} = require('./models')
const init = require('./init.js')

const force = false

const app = express()
app.use(bodyParser.json())
app.use(cors())
app.use(morgan('combined'))
require('./routes')(app)

const server = http.createServer(app)

sequelize.sync({force})
  .then(() => {
    force && init()
    server.listen(8085)
  }
)
