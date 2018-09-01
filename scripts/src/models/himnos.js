module.exports = (sequelize, DataTypes) => 
  sequelize.define('himnos', {
    titulo: DataTypes.STRING
  })