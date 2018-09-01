module.exports = (sequelize, DataTypes) => 
  sequelize.define('sub_tema_himno', {
    himno_id: {
      type: DataTypes,
      references: {
        model: 'himnos',
        key: 'id'
      }
    },
    sub_tema_id: {
      type: DataTypes,
      references: {
        model: 'sub_temas',
        key: 'id'
      }
    }
  })