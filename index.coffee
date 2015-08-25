Telegram = require('telegram-bot')
sqlite = require('sqlite3')

blacklist = ["help", "add", "list"]

db_file = "kindergarten.db"
db = new sqlite.Database db_file
db.run "CREATE TABLE kindergarten (text TEXT(255), chat TEXT(25), command TEXT(25), UNIQUE(chat, command) ON CONFLICT REPLACE);",
(exeErr) ->
  console.log exeErr if exeErr
db.close()

tg = new Telegram(process.env.TELEGRAM_BOT_TOKEN)
tg.on 'message', (msg) ->
  return unless msg.text
  console.log msg.chat.id+": "+msg.text
  if msg.text.match(/^\/add.+/i)
    [_, command, text] = msg.text.match(/^\/add\s(\w+?)\s(.+?)$/)

    # blacklist
    if command in blacklist
      tg.sendMessage
        text: command+" is black-listed. Abort!"
        reply_to_message_id: msg.message_id
        chat_id: msg.chat.id
      return

    db = new sqlite.Database db_file
    db.run "INSERT INTO kindergarten (chat, command, text) VALUES ('"+
      msg.chat.id+"', '"+command+"', '"+text+"')"
    db.close()
    tg.sendMessage
      text: "New command '"+command+"' was added!"
      reply_to_message_id: msg.message_id
      chat_id: msg.chat.id
  else if msg.text.match(/^\/list/i)
    db = new sqlite.Database db_file
    db.each "SELECT command, text FROM kindergarten WHERE chat LIKE '"+msg.chat.id+"'",
    (exeErr, row) ->
      throw exeErr if exeErr
      tg.sendMessage
        text: row.command+": "+row.text
        reply_to_message_id: msg.message_id
        chat_id: msg.chat.id
  else if msg.text.match(/^\//)
    [_, command] = msg.text.match(/^\/(\w+)$/)
    text = msg.text.replace('/','')
    db = new sqlite.Database db_file
    db.each "SELECT text FROM kindergarten WHERE command LIKE '"+
      command+"' AND chat LIKE '"+msg.chat.id+"' LIMIT 1",
    (exeErr, row) ->
      throw exeErr if exeErr
      tg.sendMessage
        text: row.text
        reply_to_message_id: msg.message_id
        chat_id: msg.chat.id
    db.close()

tg.start()
