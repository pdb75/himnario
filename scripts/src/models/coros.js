module.exports = (sequelize, DataTypes) => 
  sequelize.define('coros', {
    titulo: DataTypes.STRING,
    tono: DataTypes.STRING,
    coro: DataTypes.TEXT
  })