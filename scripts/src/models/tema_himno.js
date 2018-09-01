module.exports = (sequelize, DataTypes) => 
  sequelize.define('tema_himno', {
    himno_id: {
      type: DataTypes,
      references: {
        model: 'himnos',
        key: 'id'
      }
    },
    tema_id: {
      type: DataTypes,
      references: {
        model: 'temas',
        key: 'id'
      }
    }
  })