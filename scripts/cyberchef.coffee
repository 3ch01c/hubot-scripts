# Description:
#   Perform CyberChef operations
#
# Dependencies:
#   cyberchef
#
# Configuration:
#   None
#
# Notes:
#   None
#
# Commands:
#   hubot cyberchef fromBase64 <VALUE> - Decode VALUE from Base64
#   hubot cyberchef help <FUNCTION> - Get help on FUNCTION
#
# Author:
#   3ch01c

cyberchef = require 'cyberchef'

module.exports = (robot) ->

  robot.respond /cyberchef fromBase64 (.+)/i, (msg) ->
    value = msg.match[1]
    unless value
      return msg.reply "You didn't include a value to decode. Ask me [help cyberchef] for syntax."
    msg.reply cyberchef.fromBase64 value

  robot.respond /cyberchef help (.+)/i, (msg) ->
    value = msg.match[1]
    unless value
      return msg.reply "You didn't include a function to get help. Ask me [help cyberchef] for syntax."
    msg.reply "`#{JSON.stringify cyberchef.help value}`"
