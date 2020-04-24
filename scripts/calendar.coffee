# Description:
#   Keep track of events
#
# Dependencies:
#   "moment-timezone": "^0.5.28"
#
# Configuration:
#   None
#
# Notes:
#   There's some natural language phrases that will trigger Hubot:
#   - <event> (is|was|will be) on <date> - Set the date of an event
#   - how long since <event> - Display the relatve duration since an event
#   - how long until <event> - Display the relatve duration until an event
#   - when is <event> - Display the date and relatve duration to an
#     event
#
# Commands:
#   hubot calendar set <event> = <date expression> - Set the date of an event
#   hubot calendar get <event> - Display the date of the event
#   hubot calendar delete <event> - Delete the event
#
# Author:
#   3ch01c

moment = require "moment-timezone"

class Calendar
  constructor: (@robot) ->
    storageLoaded = =>
      @storage = @robot.brain.data.calendar ||= {}
      @robot.logger.debug "Calendar Data Loaded: " + JSON.stringify(@storage, null, 2)
    @robot.brain.on "loaded", storageLoaded
    storageLoaded() # just in case storage was loaded before we got here

  # set an event
  set: (key, value) ->
    @robot.logger.debug "setting #{key}: #{value}"
    unless key then throw new Error "You didn't provide an event. If you need help, ask me [help calendar]."
    unless value then throw new Error "You didn't provide a date. If you need help, ask me [help calendar]."
    date = moment value
    unless date.isValid() then date = moment value, "LLLL" # Thursday, September 4 1986 8:30 PM
    unless date.isValid() then date = moment value, "dddd, MMMM dd, yyyy h:mm A" # Thursday, September 4, 1986 8:30 PM
    unless date.isValid() then date = moment value, "h:mm A" # 8:30 PM
    unless date.isValid() then throw new Error "I don't understand that date format. If you need help, ask me [help calendar]."
    @robot.logger.debug "setting #{key}: #{date.unix()}"
    @storage[key] = date.unix()
    @robot.brain.save()

  # get an event
  get: (key, relative) ->
    @robot.logger.debug "getting #{key}"
    unless key then throw new Error "You didn't provide an event. If you need help, ask me [help calendar]."
    re = new RegExp key
    results = {}
    for k,v of @storage
      if re.test k
        while typeof v == "string" and v.startsWith "_"
          # factoid is an alias
          v = @storage[v.trim "_" ]
        v = moment.unix(v)
        tense = "#{if v.isBefore moment() then "was" else "is"}"
        if relative then results[k] = "#{k} #{tense} #{v.fromNow()}"
        else results[k] = "#{k} #{tense} on #{v.format("LLLL")}"
        @robot.logger.debug "found #{k}: #{results[k]}"
    results
  
  # delete an event
  delete: (key) ->
    @robot.logger.debug "deleting #{key}"
    value = @storage[key]
    delete @storage[key]
    @robot.brain.save()
    date = moment value

  confirm: (msg, message, reaction="ok") ->
    if message
      msg.reply message
    else if msg.robot.adapter.client.react
      msg.robot.adapter.client.react msg.message.id, reaction
    else
      msg.reply "You got it, boss."

module.exports = (robot) ->  
  calendar = new Calendar robot

  robot.respond /calendar set (.+) = (.+)/i, (msg) ->
    event = msg.match[1].trim()
    date = msg.match[2].trim()
    try
      calendar.set event, date
      calendar.confirm msg
    catch e
      robot.logger.debug e
      calendar.confirm msg, e.message, "shrug"

  robot.respond /calendar get (.+)/i, (msg) ->
    event = msg.match[1].trim()
    try
      dates = calendar.get event
      for k,v of dates
        msg.reply "#{v}"
    catch e
      robot.logger.debug e
      calendar.confirm msg, e.message, "shrug"
  
  robot.respond /calendar (delete|remove) (.+)/i, (msg) ->
    event = msg.match[2].trim()
    try
      calendar.delete event
      calendar.confirm msg, "#{event} has been removed."
    catch e
      robot.logger.debug e
      calendar.confirm msg, e.message, "shrug"
  
  robot.hear /(.+) (was|is|will be) (on|at) ([^\.]+)/i, (msg) ->
    event = msg.match[1].trim()
    date = msg.match[4].trim()
    try
      calendar.set event, date
      calendar.confirm msg
    catch e
      robot.logger.debug e
      calendar.confirm msg, null, "shrug"

  robot.hear /how long (since|until) ([^\?]+)/i, (msg) ->
    event = msg.match[2].trim()
    try
      dates = calendar.get event, true
      for k,v of dates
        msg.reply "#{v}"
    catch e
      robot.logger.debug e
      calendar.confirm msg, null, "shrug"

  robot.hear /When (is|was|will be) ([^\?]+)/i, (msg) ->
    event = msg.match[2].trim()
    try
      dates = calendar.get event
      for k,v of dates
        msg.reply "#{v}"
    catch e
      robot.logger.debug e
      calendar.confirm msg, null, "shrug"

  robot.hear /What day is ([^\?]+)/i, (msg) ->
    event = msg.match[1].trim()
    try
      dates = calendar.get event
      for k,v of dates
        msg.reply "#{v}"
    catch e
      robot.logger.debug e
      calendar.confirm msg, null, "shrug"

  robot.hear /What time is ([^\?]+)/i, (msg) ->
    event = msg.match[1].trim()
    try
      dates = calendar.get event
      for k,v of dates
        msg.reply "#{v}"
    catch e
      robot.logger.debug e
      calendar.confirm msg, null, "shrug"
