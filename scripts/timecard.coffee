# Description:
#   Remind people to do their timecards.
#
# Dependencies:
#   "lodash": "^4.17.4"
#   "moment-timezone": "^0.5.9",
#
# Configuration:
# HUBOT_TIMECARD_ANNOUNCE_CHANNEL - default announcement channel
#
# Notes:
#   None
#
# Commands:
#   hubot time(card)?([: ])submitted - let hubot know you submitted your time
#   hubot time(card)?([: ])announce - find out when the bomb is set to explode
#
# Author:
#   3ch01c

_ = require 'lodash'
moment = require 'moment-timezone'

ANNOUNCE_CHANNEL = process.env.HUBOT_TIMECARD_ANNOUNCE_CHANNEL

module.exports = (robot) ->
  class Timecard
    constructor: (@robot) ->
      @robot.brain.on 'loaded', =>
        @cache = @robot.brain.data.timecard or {}
        @cache['submitted'] ?= [] # currently submitted timecards
        @cache['submissionHistory'] ?= [] # past submissions
        @deadline = moment().endOf "week"
        @whuffie = @robot.brain.data.whuffie or {}

    submit: (user) =>
      unless _.includes(@cache['submitted'], user)
        @cache['submitted'].push(user)
        @robot.brain.data.timecard = @cache
        reason = 'for submitting their time on time'
        awarder = robot.name
        value = 0
        @whuffie[user] ?= []
        @whuffie[user].push(reason: reason, dateAwarded: moment().format('YY/MM/DD HH:mm'), awarder: awarder, value: value)
        @robot.brain.data.whuffie = @whuffie

    # tally up the submissions
    tally: () ->
      @cache['submissionHistory'].push(@cache['submitted'].length)
      @robot.brain.data.timecard = @cache

    # reset submissions
    reset: (msg) =>
      @cache['submitted'] = []
      # move deadline to end of week
      @deadline = moment().endOf "week"
      @robot.brain.data.timecard = @cache

    # respond with the current submissions
    announcement: () ->
      change = "the same as"
      if @cache['submitted'].length > _.last(@cache['submissionHistory'])
          change = "#{@cache['submitted'].length - _.last(@cache['submissionHistory'])} more than"
      if @cache['submitted'].length < _.last(@cache['submissionHistory'])
          change = "#{_.last(@cache['submissionHistory']) - @cache['submitted'].length} less than"
      "#{@cache['submitted'].length} of you entered time on time this week. That's #{change} last week!"

    # print out some stats
    stats: () ->
      weeks = @cache['submissionHistory'].length
      max = _.max(@cache['submissionHistory'])
      """
      Since we started keeping track #{weeks} week(s) ago, #{_.sum(@cache['submissionHistory'])} people have submitted their time on time.
      The record was #{weeks - _.indexOf(@cache['submissionHistory'], max)} week(s) ago when #{max} people submitted their time on time.
      On an average week, #{_.mean(@cache['submissionHistory'])} people submit their time on time.
      """

    confirm: (msg) ->
      if @robot.adapter.client?.web?.reactions?
        @robot.adapter.client.web.reactions.add('ok_hand', {channel: msg.message.room, timestamp: msg.message.id})
      else
        msg.send("OK!")

    timecard = new Timecard robot

    setInterval ->
      if timecard.deadline?
        # wait for deadline, then tally up time card entries, make an announcement, and reset the counter
        if timecard.deadline.diff(moment(), 'seconds') < 0
          timecard.tally()
          robot.messageRoom ANNOUNCE_CHANNEL, "#{timecard.announcement()}"
          timecard.reset()
    , 1000

    robot.respond /time(card)?([: ])submitted/i, (msg) ->
      user = msg.message.user.name
      timecard.submit(user)
      timecard.confirm(msg)

    robot.respond /time(card)?([: ])announce/i, (msg) ->
      msg.send "#{timecard.announcement()}"

    robot.respond /time(card)?([: ])reset/i, (msg) ->
      timecard.reset()
      timecard.confirm(msg)

    robot.respond /time(card)?([: ])tally/i, (msg) ->
      timecard.tally()
      timecard.confirm(msg)

    robot.respond /time(card)?([: ])stats/i, (msg) ->
      msg.send "#{timecard.stats()}"
