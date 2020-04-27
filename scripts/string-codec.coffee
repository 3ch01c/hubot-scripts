# Description
#   A hubot script that encode/decode string
#
# Dependencies:
#   "string-codec"
#   "xmorse"
#
# Configuration:
#   None
#
# Notes:
#   morse format example: ... --- ... = SOS
#
# Commands:
#   hubot encode <algo> <string> - encode a string with specified algorithm
#   hubot encode list - list of all available algorithm
#   hubot decode <algo> <string> - decode a string with specified algorithm
#   hubot decode list - list of all available algorithm
#
# Author:
#   knjcode <knjcode@gmail.com>
#   hashashin
#   3ch01c

codec = require 'string-codec'
xmorse = require 'xmorse'

module.exports = (robot) ->
  option =
    space: process.env.HUBOT_MORSE_SPACE || ' '
    long: process.env.HUBOT_MORSE_LONG || '-'
    short: process.env.HUBOT_MORSE_SHORT || '.'
  encodings = codec.ENC_ALL.concat(["morse"])
  decodings = codec.DEC_ALL.concat(["morse"])

  robot.respond /enc(ode)? (\w*) (.*)/i, (msg) ->
    algo = msg.match[2]
    str = msg.match[3]
    if algo in codec.ENC_ALL
      msg.send codec.encoder(str, algo)
    else if algo == "morse"
      msg.send xmorse.encode(str, option)
    else
      msg.send "I'm afraid I can't do that encoding."

  robot.respond /dec(ode)? (\w*) (.*)/i, (msg) ->
    algo = msg.match[2]
    str = msg.match[3]
    if algo in codec.DEC_ALL
      msg.send codec.decoder(str, algo)
    else if algo == "morse"
      msg.send xmorse.decode(str, option)
    else
      msg.send "I'm afraid I can't do that decoding."

  robot.respond /enc(ode)?( list)?$/i, (msg) ->
    msg.send "I know the following encodings: `#{encodings.toString()}`"

  robot.respond /dec(ode)?( list)?$/i, (msg) ->
    msg.send "I know the following decodings: `#{decodings.toString()}`"