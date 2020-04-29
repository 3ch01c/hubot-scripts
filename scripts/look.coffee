# Description:
#   Display a look from looks.wtf
#
# Dependencies:
#   "lodash": "4.17.15"
#   "yamljs": "0.3.0"
#
# Configuration:
#   None
#
# Notes:
#   None
#
# Commands:
#   hubot look LOOK - Display a look from looks.wtf
#
# Author:
#   3ch01c

YAML = require "yamljs"
_ = require "lodash"

LOOKS_URL = "https://raw.githubusercontent.com/leighmcculloch/looks.wtf/master/looks.yml"

module.exports = (robot) ->

  robot.respond /look( [\w-]+)?$/i, (msg) ->
    look = msg.match[1]?.trim() or "all"
    @robot.http(LOOKS_URL).get() (err, res, body) ->
      if res.statusCode == 200
        looks = YAML.parse body
      else
        robot.logger.debug res.statusCode
        return msg.reply "I'm afraid I can do that. There's been an error."
      filtered = _.filter looks, (o) -> o.tags.includes look
      looks = _.map filtered, (o) -> return o.plain
      msg.reply msg.random looks

  robot.respond /flip something$/i, (msg) ->
    look = "flip"
    @robot.http(LOOKS_URL).get() (err, res, body) ->
      if res.statusCode == 200
        looks = YAML.parse body
      else
        robot.logger.debug res.statusCode
        return msg.reply "I'm afraid I can do that."
      filtered = _.filter looks, (o) -> o.tags.includes look
      looks = _.map filtered, (o) -> return o.plain
      msg.reply msg.random looks