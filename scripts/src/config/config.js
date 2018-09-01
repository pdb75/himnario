const path = require('path')

module.exports = {
  port: process.env.PORT || 8085,
  db: {
    database: process.env.DB_NAME || 'himnos_coros',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASS || 'root',
    options: {
      dialect: process.env.DIALECT || 'sqlite',
      host: process.env.HOST || 'localhost',
      storage: path.resolve(__dirname, '../../himnos_coros.sqlite')
    }
  },
  certificacion: {
    jwtSecret: process.env.JWT_SECTRET || 'secret'
  }
}
