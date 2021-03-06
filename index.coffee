Bot = require('telegram-api')
Message = require('telegram-api/types/Message')
File = require('telegram-api/types/File')

sqlite = require('sqlite3')

debug = false
blacklist = ["help", "add", "list", "stats", "random", "fixbot", "roll"]

db_file = "kindergarten.db"
db = new sqlite.Database db_file
db.run "CREATE TABLE kindergarten (text TEXT(255), chat TEXT(25), "+
  "command TEXT(25), UNIQUE(chat, command) ON CONFLICT REPLACE);",
  (exeErr) -> console.log exeErr if exeErr
db.close()

bot = new Bot({token: process.env.TELEGRAM_BOT_TOKEN})
bot.start()

send = (cmd, text) ->
  answer = new Message()
    .text(text)
    .to(cmd.chat.id)
  bot.send(answer)

bot.get /^(hi|hey|hallo|hello|yo)$/i, (msg) ->
  send msg, 'Hello, Sir'

help = "add <new command> <text> - Add a new command\n"+
  "list [<page number>] - List known commands\n"+
  "help - Help page"

bot.command 'start', (msg) ->
  send msg, help
bot.command 'help', (msg) ->
  send msg, help

bot.command 'add', (msg) ->
  console.log msg if debug

  if msg.text.match(/^\/add\s[\w\d]+\s.+$/i)
    [_, command, text] = msg.text.match(/^\/add\s([\w\d]+?)\s(.+?)$/)
    # check on existence
    unless command? and text?
      return

    # blacklist
    if command in blacklist
      send msg, command+" is black-listed. Abort!"
      return

    # remove evil manu chars
    text = text.replace /['"]/g, ""

    db = new sqlite.Database db_file
    db.run "INSERT INTO kindergarten (chat, command, text) VALUES ('"+
      msg.chat.id+"', '"+command+"', '"+text+"')"
    db.close()
    send msg, "New command '"+command+"' was added!"

bot.command 'stats', (msg) ->
  console.log msg if debug
  if msg.text.match(/^\/stats$/i)
    db = new sqlite.Database db_file
    db.each "SELECT count(*) as 'count' FROM kindergarten "+
      "WHERE chat LIKE '"+msg.chat.id+"'",
      (exeErr, row) ->
        console.log exeErr if exeErr
        send msg, "There are/is "+row.count+" command(s) available!"
    db.close()

bot.get /^\/roll.*$/, (msg) ->
  console.log msg if debug
  [min, max] = [1, 10]
  if msg.text.match(/^\/roll\s(\d*)$/)
    [_, max] = msg.text.match(/^\/roll\s(\d*)$/)
  rand = Math.floor(Math.random() * (parseInt(max) - min) + min)
  send msg, "You roll "+rand+"("+min+"-"+max+")"

bot.get /^\/(rnd|random)$/i, (msg) ->
  console.log msg if debug
  db = new sqlite.Database db_file
  db.each "SELECT command, text FROM kindergarten "+
    "WHERE chat LIKE '"+msg.chat.id+"' "+
    "AND _ROWID_ >= (abs(random()) % (SELECT max(_ROWID_) FROM kindergarten)) "+
    "LIMIT 1",
    (exeErr, row) ->
      console.log exeErr if exeErr
      send msg, "/"+row.command+" "+row.text
  db.close()

bot.get /^\/[\w\d]+$/, (msg) ->
  console.log msg if debug
  if msg.text.match(/^\//)
    [_, command] = msg.text.match(/^\/([\w\d]+)$/)
    text = msg.text.replace('/','')
    db = new sqlite.Database db_file
    db.each "SELECT text FROM kindergarten WHERE command LIKE '"+
      command+"' AND chat LIKE '"+msg.chat.id+"' LIMIT 1",
      (exeErr, row) ->
        console.log exeErr if exeErr
        send msg, row.text
    db.close()

bot.get /^\/[^\w\d]+$/, (msg) ->
  send msg, "Danke Andy.."
