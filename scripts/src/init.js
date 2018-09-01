const {temas, himnos, parrafos, coros, sub_temas, sub_tema_himno, tema_himno} = require('./models')
const path = require('path')
const fs = require('fs')


const himnosTXT = fs.readFileSync(path.join(__dirname, './initmodels/himnos.txt'), 'utf8')
const himnosInit = himnosTXT.split('\r\n')

const temasTXT = fs.readFileSync(path.join(__dirname, './initmodels/temas.txt'), 'utf8')
const temasInit = temasTXT.split('\r\n')

const sub_temasTXT = fs.readFileSync(path.join(__dirname, './initmodels/sub_temas.txt'), 'utf8')
const sub_temasInit = sub_temasTXT.split('\r\n')

const sub_temas_himnosTXT = fs.readFileSync(path.join(__dirname, './initmodels/sub_tema_himno.txt'), 'utf8')
const sub_temas_himnosInit = sub_temas_himnosTXT.split('\r\n')

const temas_himnosTXT = fs.readFileSync(path.join(__dirname, './initmodels/tema_himno.txt'), 'utf8')
const temas_himnosInit = temas_himnosTXT.split('\r\n')

module.exports = async () => {
  for (let himno of himnosInit) await himnos.create({titulo: himno})
  for (let tema of temasInit) await temas.create({tema})
  for (let sub_tema of sub_temasInit) {
    sub_tema = sub_tema.split(', ')
    await sub_temas.create({
      sub_tema: sub_tema[1],
      tema_id: sub_tema[0]
    })
  }
  for (let himno of sub_temas_himnosInit) {
    himno = himno.split(', ')
    await sub_tema_himno.create({
      himno_id: himno[1],
      sub_tema_id: himno[0]
    })
  }
  for (let himno of temas_himnosInit) {
    himno = himno.split(', ')
    await tema_himno.create({
      himno_id: himno[1],
      tema_id: himno[0]
    })
  }
}
