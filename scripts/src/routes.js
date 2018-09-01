const fs = require('fs')
const path = require('path')
const {sequelize} = require('./models')
const mp3Duration = require('mp3-duration')

module.exports = (app) => {
  app.get('/bajo', (req, res) => {
    const audio = fs.createReadStream(path.resolve(__dirname, './himnos/71/Bajo.mp3'))
    audio.pipe(res)
  })
  app.get('/soprano', (req, res) => {
    const audio = fs.createReadStream(path.resolve(__dirname, './himnos/71/Soprano.mp3'))
    audio.pipe(res)
  })
  app.get('/tenor', (req, res) => {
    const audio = fs.createReadStream(path.resolve(__dirname, './himnos/71/Tenor.mp3'))
    audio.pipe(res)
  })
  app.get('/contraalto', (req, res) => {
    const audio = fs.createReadStream(path.resolve(__dirname, './himnos/71/ContraAlto.mp3'))
    audio.pipe(res)
  })
  app.get('/categorias', async (req, res) => {
    var categorias = (await sequelize.query('select * from temas'))[0]
    res.send(JSON.stringify(categorias))
  })

  app.get('/voz_disponible', async (req, res) => {
    res.send(fs.readdirSync(path.resolve(__dirname, './himnos')))
  })

  app.get('/duracion', async (req, res) => {
    mp3Duration(path.resolve(__dirname, './himnos/71/Tenor.mp3'), function (err, duration) {
      if (err) return console.log(err.message)
      console.log('Your file is ' + duration + ' seconds long')
      res.send({duration})
    })
  })

  app.get('/categorias/:sub_categoria', async (req, res) => {
    var categorias = (await sequelize.query(`select * from sub_temas where tema_id = '${req.params.sub_categoria}'`))[0]
    res.send(JSON.stringify(categorias))
  })

  app.get('/categorias/:id/himnos', async (req, res) => {
    var himnos = (await sequelize.query(`select himnos.id, himnos.titulo from himnos join temas on himnos.tema_id = temas.id where tema_id = '${req.params.id}'`))[0]
    res.send(JSON.stringify(himnos))
  })

  app.get('/sub_categorias/:id/himnos', async (req, res) => {
    var himnos = (await sequelize.query(`select himnos.id, himnos.titulo from himnos join sub_tema_himnos on sub_tema_himnos.himno_id = himnos.id where sub_tema_himnos.sub_tema_id = '${req.params.id}'`))[0]
    res.send(JSON.stringify(himnos))
  })
}

// const mediaserver = require('mediaserver')

// module.exports = (app) => {
//   app.get('/', (req, res) => {
//     mediaserver.pipe(req, res, path.join(__dirname, './himnos/71/Soprano.mp3'))
//   })
// }