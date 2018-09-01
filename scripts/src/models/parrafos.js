module.exports = (sequelize, DataTypes) => 
  sequelize.define('parrafos', {
    numero_order: DataTypes.INTEGER,
    coro: DataTypes.BOOLEAN,
    parrafo: DataTypes.TEXT,
    himno_id: {
      type: DataTypes.INTEGER,
      references: {
        model: 'himnos',
        key: 'id'
      }
    }
  })