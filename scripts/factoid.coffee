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
#   If you want to alias a factoid to another factoid, set its value to an
#   underscore followed by the target factoid.
#
# Commands:
#   hubot factoid learn <KEY> = <VALUE> - set a factoid
#   hubot factoid forget <KEY> - delete a factoid
#   hubot factoid recall <KEY> - get factoid(s)
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
      unless key? and value?
        throw new Error "You didn't provide a factoid to learn. If you need help, ask me [help factoid]."
      @storage[key] = value
      @robot.brain.save()

    # get factoid(s)
    get: (key) ->
      unless key?
        throw new Error "You didn't provide a factoid to recall. If you need help, ask me [help factoid]."
      results = null
      re = new RegExp key
      for k,v of @storage
        if re.test k
          results ?= {}
          while typeof v == "string" and v?.startsWith "_"
            # factoid is an alias. strip off the _
            v = @storage[v.substring 1, v.length]
          results[k] = v
      results

    # delete a factoid
    delete: (key) ->
      unless key?
        throw new Error "You didn't provide a factoid to delete. If you need help, ask me [help factoid]."
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
    
  factoid = new Factoid robot

  # set a factoid
  robot.respond /factoid (set|learn) ([^=]+)=([^=]+)$/i, (res) ->
    key = res.match[2].trim()
    value = res.match[3].trim()
    try
      factoid.set key, value
      factoid.acknowledge res, "OK", "ok"
    catch e
      robot.logger.debug e
      factoid.acknowledge res, e.message

  # set a factoid (shorthand)
  robot.hear /!([^=]+)=([^=]+)$/i, (res) ->
    key = res.match[1].trim()
    value = res.match[2].trim()
    try
      factoid.set key, value
      factoid.acknowledge res, "OK", "ok"
    catch e
      robot.logger.debug e
      factoid.acknowledge res, e.message

  # get a factoid
  robot.respond /factoid (get|recall) ([^=]+)$/i, (res) ->
    key = res.match[2].trim()
    try
      values = factoid.get key
      unless values?
        factoid.acknowledge res, "I don't know a factoid like that.", "shrug"
      else
        for k,v of values
          res.reply "#{k} is #{v}"
    catch e
      robot.logger.debug e
      factoid.acknowledge res, e.message

  # get a factoid (shorthand)
  robot.hear /!([^=]+)$/i, (res) ->
    key = res.match[1].trim()
    try
      values = factoid.get key
      unless values?
        factoid.acknowledge res, "I don't know a factoid like that.", "shrug"
      else
        for k,v of values
          res.reply "#{k} is #{v}"
    catch e
      robot.logger.debug e
      factoid.acknowledge res, e.message
  
  # get a factoid (nlp)
  robot.hear /(.+)\?$/i, (res) ->
    key = res.match[1].trim()
    robot.logger.debug "key: #{key}"
    try
      values = factoid.get key
      unless values?
        factoid.acknowledge res, "I don't know a factoid like that.", "shrug"
      else
        for k,v of values
          res.reply "#{v}"
    catch e
      robot.logger.debug e
      factoid.acknowledge res, e.message

  # delete a factoid
  robot.respond /factoid (delete|forget) ([^=]+)$/i, (res) ->
    key = res.match[2].trim()
    try
      value = factoid.delete key
      unless value?
        factoid.acknowledge res, "I don't know a factoid like that.", "shrug"
      else
        factoid.acknowledge res, "OK", "ok"
    catch e
      robot.logger.debug e
      factoid.acknowledge res, e.message