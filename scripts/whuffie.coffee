# Description:
#   Award or revoke whuffie from users
#
# Dependencies:
#   "lodash": "^1.8.3"
#   "moment-timezone": "^0.5.9",
#   "yamljs": "^0.2.8"
#
# Configuration:
#   None
#
# Notes:
#   None
#
# Commands:
#   @<USER> ++[ for <REASON>] - award whuffie to USER (for REASON)
#   @<USER> --[ for <REASON>] - revoke whuffie from USER (for REASON)
#   hubot whuffie[ top <N>] - list whuffie for (top N) users (default: N=10)
#   hubot whuffie @<USER> - list whuffie details for USER
#
# Author:
#   Jack Miner <3ch01c@gmail.com>

_ = require 'lodash'
moment = require 'moment-timezone'
YAML = require 'yamljs'

module.exports = (robot) ->
  class Whuffie
    constructor: (@robot) ->
      if @robot.brain?
        @robot.brain.on 'loaded', =>
          @cache = @robot.brain.get 'whuffie' or {}
      else
          @cache = @robot.brain.get 'whuffie' or {}
      @cache ?= {}

    # award whuffie for something somebody did
    award: (user, awarder, reason = 'for no reason', value) ->
      @cache[user] ?= []
      @cache[user].push(reason: reason, dateAwarded: moment().format('YYYY/MM/DD HH:mm'), awarder: awarder, value: value)
      @robot.brain.set('whuffie', @cache)

    revoke: (user, date) ->
      indx = @cache[user].findIndex (element) -> element.dateAwarded is date
      if indx > -1
        @cache[user].splice(indx, 1)
      delete @cache[user] if @cache[user].length is 0
      @robot.brain.set('whuffie', @cache)

    # return total whuffie for user
    getTotal: (user) ->
      total = 0
      total += record.value for record in @cache[user] if @cache[user]

    # returns details of everything contributing to user's whuffie
    getDetails: (user) ->
      details = "Whuffie details for #{user}:\n"
      if @cache[user]
        details += ("#{record.dateAwarded}: #{record.value} #{record.reason} (awarded by #{record.awarder})" for record in @cache[user]).join('\n')
        details += "\n#{user} has #{@getTotal(user)} whuffie"
      else
        details += "#{user} hasn't done anything notable yet"

    # returns a formatted list of users sorted by whuffie in descending order
    getRankedList: (limit) ->
      limit ?= 8
      details = "Whuffie top #{limit}:\n"
      counts = _.map @cache, (user, name) =>
        {name: name, count: @getTotal(name)}
      ranked = _.sortBy counts, (user) =>
        -user.count
      max = ranked[0].count
      console.log ranked
      details += ("#{":whuffie:".repeat(Math.max(0,Math.ceil(user.count*8/max)))} @#{user.name}" for user in (_.take ranked, limit)).join('\n')

    export: (format) =>
      if format is 'json'
        JSON.stringify @cache
      else if format is 'yaml'
        YAML.stringify @cache

    confirm: (msg, reaction="ok", reply="You got it, boss.") ->
      if msg.robot?.adapter?.client?.react?
        msg.robot.adapter.client.react(msg.message.id, reaction)
      else
        msg.reply(reply)

  whuffie = new Whuffie robot

  robot.hear /^@?(\S+):? ?([\+|-]{2})( .+)/i, (res) ->
    awarder = res.message.user.name.toLowerCase()
    user = res.match[1].toLowerCase()
    unless awarder is user
      if res.match[2] is '++'
        value = 1
      else if res.match[2] is '--'
        value = -1
      if res.match[3]
        reason = res.match[3].trim()
      whuffie.award(user, awarder, reason, value)
      whuffie.confirm(res)
    else
      res.reply "How about @#{user} -- for trying to award themselves whuffie?"

  robot.respond /whuffie revoke @?(\S+) (\d{2,4}(\/\d{2}){2} \d{2}:\d{2})/i, (res) ->
    user = res.match[1]
    date = res.match[2]
    whuffie.revoke(user, date)
    whuffie.confirm(res, '-1')

  robot.respond /whuffie export( (yaml|json))?/i, (res) ->
    format = res.match[2] or "json"
    res.reply "#{whuffie.export(format)}"

  robot.respond /whuffie( details)? @?(\S+)/i, (res) ->
    user = res.match[2]
    res.reply "#{whuffie.getDetails(user)}"

  robot.respond /whuffie top( (\d+))?$/i, (res) ->
    limit = parseInt res.match[2] or 10
    res.reply "#{whuffie.getRankedList(limit)}"

  robot.respond /Thanks/i, (res) ->
    whuffie.confirm(res, "+1", "You're welcome!")