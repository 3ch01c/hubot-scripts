# Description:
#   Teach hubot factoids
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Notes:
#   None
#
# Commands:
#   hubot factoid learn <KEY> = <VALUE> - set factoid KEY to VALUE
#   hubot factoid forget <KEY> - delete factoid KEY
#   hubot factoid recall <REGEX> - get factoids matching regex REGEX
#   hubot factoid alias <ALIAS> = <KEY> - set factoid ALIAS to factoid KEY
#
# Author:
#   3ch01c

module.exports = (robot) ->
  class Factoid
    constructor: (@robot) ->
      storageLoaded = =>
        @storage = @robot.brain.data.factoid ||= {}
        @robot.logger.debug "Factoid Data Loaded: " + JSON.stringify(@storage, null, 2)
      @robot.brain.on "loaded", storageLoaded
      storageLoaded() # just in case storage was loaded before we got here

    # set a factoid
    set: (key, value) ->
      @storage[key] = value
      @robot.brain.save()

    # get a factoid
    get: (key, exact=false) ->
      re = new RegExp key
      results = {}
      for k,v of @storage
        if re.test k
          while v.startsWith "_"
            # factoid is an alias
            v = @storage[v.trim "_" ]
          results[k] = v
      results

    # delete a factoid
    delete: (key) ->
      value = @storage[key]
      delete @storage[key]
      @robot.brain.save()
      value

    # alias a factoid
    alias: (key) ->
      value = @storage[key]
      if value
        @storage[alias] = "_#{key}"
        @robot.brain.save()
      value

    confirm: (msg, reaction="ok", reply="You got it, boss.") ->
      if msg.robot?.adapter?.client?.react?
        msg.robot.adapter.client.react(msg.message.id, reaction)
      else
        msg.reply(reply)

  factoid = new Factoid robot

  robot.respond /factoid( (set|learn))? (.+) = (.+)$/i, (res) ->
    key = res.match[3].trim()
    value = res.match[4].trim()
    unless key and value
      res.reply "You didn't include a factoid to learn. Ask me [help factoid] for syntax."
    else
      factoid.set key, value
      factoid.confirm(res)

  robot.respond /!([^=]+)=(.+)$/i, (res) ->
    key = res.match[1].trim()
    value = res.match[2].trim()
    unless key and value
      res.reply "You didn't include a factoid to learn. Ask me [help factoid] for syntax."
    else
      factoid.set key, value
      factoid.confirm(res)

  robot.respond /factoid (delete|forget) (.+)$/i, (res) ->
    key = res.match[2].trim()
    unless key
      res.reply "You didn't include a factoid to forget. Ask me [help factoid] for syntax."
    else
      value = factoid.delete key
      factoid.confirm(res)

  robot.respond /factoid( (get|recall))? (.+)$/i, (res) ->
    key = res.match[3].trim()
    unless key
      res.reply "You didn't include a factoid to recall. Ask me [help factoid] for syntax."
    else
      values = factoid.get key
      unless values?
        res.reply "I don't know a factoid like that."
      else
        for k,v of values
          res.reply "#{k} is #{v}"

  robot.hear /!(.+)$/i, (res) ->
    key = res.match[1].trim()
    unless key
      res.reply "You didn't include a factoid to recall. Ask me [help factoid] for syntax."
    else
      values = factoid.get key
      unless values?
        res.reply "I don't know a factoid like that."
      else
        for k,v of values
          res.reply "#{k} is #{v}"
  
  robot.hear /(.+)\?$/i, (res) ->
    key = res.match[1].trim()
    values = factoid.get key
    for k,v of values
      res.reply "#{v}"

  robot.respond /factoid alias (.+) is (.+)$/i, (res) ->
    alias = res.match[1].trim()
    key = res.match[2].trim()
    unless alias and key 
      res.reply "You didn't include a factoid to alias. Ask me [help factoid] for syntax."
    else
      value = factoid.alias key
      unless value
        res.reply "I don't know a factoid like that."
      else
        factoid.confirm(res)
