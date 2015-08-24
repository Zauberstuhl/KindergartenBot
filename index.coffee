Telegram = require('telegram-bot')
sqlite = require('sqlite3')

db_file = "kindergarten.db"
db = new sqlite.Database db_file
db.run "CREATE TABLE kindergarten (command TEXT(25) UNIQUE, text TEXT(25))",
(exeErr) ->
  console.log exeErr if exeErr
db.close()

tg = new Telegram(process.env.TELEGRAM_BOT_TOKEN)
tg.on 'message', (msg) ->
  return unless msg.text
  console.log msg.text
  if msg.text.match(/^\/add.+/)
    [_, command, text] = msg.text.match(/^\/add\s(\w+?)\s(.+?)$/)
    db = new sqlite.Database db_file
    db.run "INSERT OR REPLACE INTO kindergarten (command, text) VALUES ('"+command+"', '"+text+"')"
    db.close()
    tg.sendMessage
      text: "New command '"+command+"' was added!"
      reply_to_message_id: msg.message_id
      chat_id: msg.chat.id
  else if msg.text.match(/^\//)
    [_, command] = msg.text.match(/^\/(\w+)$/)
    text = msg.text.replace('/','')
    db = new sqlite.Database db_file
    db.each "SELECT text FROM kindergarten WHERE command LIKE '"+command+"' LIMIT 1",
    (exeErr, row) ->
      throw exeErr if exeErr
      tg.sendMessage
        text: row.text
        reply_to_message_id: msg.message_id
        chat_id: msg.chat.id
    db.close()

tg.start()
