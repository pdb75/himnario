module.exports = (sequelize, DataTypes) => 
  sequelize.define('sub_temas', {
    sub_tema: DataTypes.STRING,
    tema_id: {
      type: DataTypes.INTEGER,
      references: {
        model: 'temas',
        key: 'id'
      }
    }
  })