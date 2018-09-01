const path = require('path')
const fs = require('fs')
const Sequelize = require('sequelize')
const config = require('../config/config')
const db = {}

const sequelize = new Sequelize(
  config.db.database,
  config.db.user,
  config.db.password,
  config.db.options
)

fs
  .readdirSync(__dirname)
  .filter(archivo => archivo !== 'index.js')
  .forEach(archivo => {
    const model = sequelize.import(path.join(__dirname, archivo))
    db[model.name] = model
  })

db.sequelize = sequelize
db.Sequelize = Sequelize

module.exports = db
