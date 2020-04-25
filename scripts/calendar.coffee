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

module.exports = (robot) ->  
  class Calendar
    constructor: (@robot) ->
      storageLoaded = =>
        @storage = @robot.brain.data.calendar ||= {}
        @robot.logger.debug "calendar: " + JSON.stringify(@storage, null, 2)
      @robot.brain.on "loaded", storageLoaded
      storageLoaded() # just in case storage was loaded before we got here

    # set an event
    set: (key, value) ->
      unless key? and value?
        throw new Error "You didn't provide an event to set. If you need help, ask me [help calendar]."
      date = moment value
      unless date.isValid()
        date = moment value, "LLLL" # Thursday, September 4 1986 8:30 PM
      unless date.isValid()
        date = moment value, "dddd, MMMM dd, yyyy h:mm A" # Thursday, September 4, 1986 8:30 PM
      unless date.isValid()
        date = moment value, "h:mm A" # 8:30 PM
      unless date.isValid()
        throw new Error "I don't understand that date format. If you need help, ask me [help calendar]."
      @storage[key] = date.unix()
      @robot.brain.save()

    # get an event
    get: (key, relative) ->
      unless key
        throw new Error "You didn't provide an event to get. If you need help, ask me [help calendar]."
      results = null
      re = new RegExp key
      for k,v of @storage
        if re.test k
          results ?= {}
          while typeof v == "string" and v?.startsWith "_"
            # calendar is an alias. strip off the _
            v = @storage[v.substring 1, v.length]
          results[k] = moment.unix(v)
      results
    
    # delete an event
    delete: (key) ->
      unless key?
        throw new Error "You didn't provide an event to delete. If you need help, ask me [help calendar]."
      value = @storage[key]
      delete @storage[key]
      @robot.brain.save()
      value

    # acknowledge a message
    acknowledge: (msg, message, reaction) ->
      if reaction? and msg.robot.adapter.client.react?
        msg.robot.adapter.client.react msg.message.id, reaction
      else
        msg.reply message

  tense = (date, plural) ->
    if date.isBefore moment() then "was" else "is"

  calendar = new Calendar robot

  # set an event
  robot.respond /calendar set ([^=]+)=([^=]+)/i, (res) ->
    event = res.match[1].trim()
    date = res.match[2].trim()
    try
      calendar.set event, date
      calendar.acknowledge res, "OK", "ok"
    catch e
      robot.logger.debug e
      calendar.acknowledge res, e.message

  # set an event (nlp)
  robot.hear /(.+) (was|is|will be) (on|at) ([^\.]+)/i, (res) ->
    event = res.match[1].trim()
    date = res.match[4].trim()
    try
      calendar.set event, date
      calendar.acknowledge res, "OK", "ok"
    catch e
      robot.logger.debug e
      calendar.acknowledge res, e.message

  # get an event date
  robot.respond /calendar get (.+)/i, (res) ->
    event = res.match[1].trim()
    try
      dates = calendar.get event
      unless dates?
        calendar.acknowledge res, "I don't know an event like that.", "shrug"
      else
        for k,v of dates
          res.reply "#{k} #{tense v} on #{v.format("LLLL")}"
    catch e
      robot.logger.debug e
      calendar.acknowledge res, e.message
  
  # get an event date relative to now (nlp)
  robot.hear /how long (since|until) ([^\?]+)/i, (res) ->
    event = res.match[2].trim()
    try
      dates = calendar.get event
      unless dates?
        calendar.acknowledge res, "I don't know an event like that.", "shrug"
      else
        for k,v of dates
          res.reply "#{k} #{tense v} #{v.fromNow()}"
    catch e
      robot.logger.debug e
      calendar.acknowledge res, e.message

  # get an event date (nlp)
  robot.hear /When (is|was|will be) ([^\?]+)/i, (res) ->
    event = res.match[2].trim()
    try
      dates = calendar.get event
      unless dates?
        calendar.acknowledge res, "I don't know an event like that.", "shrug"
      else
        for k,v of dates
          res.reply "#{k} #{tense v} on #{v.format("LLLL")}"
    catch e
      robot.logger.debug e
      calendar.acknowledge res, e.message

  # get an event day (nlp)
  robot.hear /What day is ([^\?]+)/i, (res) ->
    event = res.match[1].trim()
    try
      dates = calendar.get event
      unless dates?
        calendar.acknowledge res, "I don't know an event like that.", "shrug"
      else
        for k,v of dates
          res.reply "#{k} #{tense v} on #{v.format("dddd")}"
    catch e
      robot.logger.debug e
      calendar.acknowledge res, e.message

  # get an event time (nlp)
  robot.hear /What time is ([^\?]+)/i, (res) ->
    event = res.match[1].trim()
    try
      dates = calendar.get event
      unless dates?
        calendar.acknowledge res, "I don't know an event like that.", "shrug"
      else
        for k,v of dates
          res.reply "#{k} #{tense v} at #{v.format("HH:mm")}"
    catch e
      robot.logger.debug e
      calendar.acknowledge res, e.message

  # delete an event
  robot.respond /calendar (delete|remove) (.+)/i, (res) ->
    event = res.match[2].trim()
    try
      value = calendar.delete event
      unless value?
        factoid.acknowledge res, "I don't know an event like that.", "shrug"
      else
        calendar.acknowledge res, "OK", "ok"
    catch e
      robot.logger.debug e
      calendar.acknowledge res, e.message
