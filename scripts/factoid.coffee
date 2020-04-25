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
#   When recalling a factoid, the key is treated as a regex. To match a key
#   exactly, use ^key$. Keys and values cannot contain equal signs.
#   Values cannot begin with an underscore.
#
# Commands:
#   hubot factoid learn <KEY> = <VALUE> - set a factoid
#   hubot factoid forget <KEY> - delete a factoid
#   hubot factoid recall <KEY> - get factoid(s)
#   hubot factoid alias <ALIAS> = <KEY> - alias a factoid
#
# Author:
#   3ch01c

module.exports = (robot) ->
  class Factoid
    constructor: (@robot) ->
      storageLoaded = =>
        @storage = @robot.brain.data.factoid ?= {}
        @robot.logger.debug "factoids: #{JSON.stringify(@storage, null, 2)}"
      @robot.brain.on "loaded", storageLoaded
      storageLoaded() # just in case storage was loaded before we got here

    # set a factoid
    set: (key, value) ->
      @storage[key] = value
      @robot.brain.save()

    # get factoid(s)
    get: (key) ->
      results = null
      re = new RegExp key
      for k,v of @storage
        if re.test k
          results ?= {}
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
      @set alias, "_#{key}"

    # acknowledge a message
    acknowledge: (msg, reaction="ok", reply="You got it, boss.") ->
      if msg.robot.adapter.client.react?
        msg.robot.adapter.client.react(msg.message.id, reaction)
      else
        msg.reply(reply)

  factoid = new Factoid robot

  # set a factoid
  robot.respond /factoid( (set|learn))? ([^=]+)=([^_][^=]+)$/i, (res) ->
    key = res.match[3].trim()
    value = res.match[4].trim()
    unless key? and value?
      res.reply "You didn't include a factoid to learn. Ask me [help factoid] for syntax."
    else
      factoid.set key, value
      factoid.acknowledge res

  # set a factoid (shorthand)
  robot.hear /!([^=]+)=([^=_]+)$/i, (res) ->
    key = res.match[1].trim()
    value = res.match[2].trim()
    unless key? and value?
      res.reply "You didn't include a factoid to learn. Ask me [help factoid] for syntax."
    else
      factoid.set key, value
      factoid.acknowledge res 

  # get a factoid
  robot.respond /factoid( (get|recall))? ([^=]+)$/i, (res) ->
    key = res.match[3].trim()
    unless key?
      res.reply "You didn't include a factoid to recall. Ask me [help factoid] for syntax."
    else
      values = factoid.get key
      unless values?
        factoid.acknowledge res, "shrug", "I don't know a factoid like that."
      else
        for k,v of values
          res.reply "#{k} is #{v}"

  # get a factoid (shorthand)
  robot.hear /!([^=]+)$/i, (res) ->
    key = res.match[1].trim()
    values = factoid.get key
    unless values?
      factoid.acknowledge res, "shrug", "I don't know a factoid like that."
    else
      for k,v of values
        res.reply "#{k} is #{v}"
  
  # get a factoid (nlp)
  robot.hear /(.+)\?$/i, (res) ->
    key = res.match[1].trim()
    robot.logger.debug "key: #{key}"
    values = factoid.get key
    unless values?
      factoid.acknowledge res, "shrug", "I don't know a factoid like that."
    for k,v of values
      res.reply "#{v}"

  # delete a factoid
  robot.respond /factoid (delete|forget) (.+)$/i, (res) ->
    key = res.match[2].trim()
    unless key?
      res.reply "You didn't include a factoid to forget. Ask me [help factoid] for syntax."
    else
      value = factoid.delete key
      factoid.acknowledge res 

  # alias a factoid
  robot.respond /factoid alias ([^=]+)=([^_][^=]+)$/i, (res) ->
    alias = res.match[1].trim()
    key = res.match[2].trim()
    unless alias? and key?
      res.reply "You didn't include a factoid to alias. Ask me [help factoid] for syntax."
    else
      value = factoid.alias key
      unless value?
        res.reply "I don't know a factoid like that."
      else
        factoid.acknowledge res 
