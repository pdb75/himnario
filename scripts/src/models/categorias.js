module.exports = (sequelize, DataTypes) => 
  sequelize.define('temas', {
    tema: DataTypes.STRING,
  })