# Description:
#   Allows hubot to answer almost any question by asking Wolfram Alpha
#
# Dependencies:
#  "xml2js": "^0.4.17",
#
# Configuration:
#   HUBOT_WOLFRAM_APPID - your AppID
#
# Commands:
#   hubot calc <question> - Searches Wolfram Alpha for the answer to the question
#
# Author:
#   dhorrigan

xml2js = require 'xml2js'
parser = xml2js.Parser()

module.exports = (robot) ->
  robot.respond /calc(ulat(e|or))? (.*)$/i, (msg) ->
    if process.env.HUBOT_WOLFRAM_APPID?
      expr = msg.match[3]
      console.log expr
      uri = "http://api.wolframalpha.com/v2/query?input=#{encodeURIComponent(expr)}&primary=true&appid=#{process.env.HUBOT_WOLFRAM_APPID}"
      console.log uri
      robot.http(uri).get() (err, response, body) ->
        if err?
          throw err
        else
          parser.parseString body, (err, results) ->
            console.log JSON.stringify results
            answer = "Well, that one is a bit of an enigma."
            if err?
              throw err
            else if results.queryresult.$.success != 'false'
              answer = results.queryresult.pod[1].subpod[0].plaintext[0]
              console.log answer
            else
              console.log results.queryresult.didyoumeans[0].didyoumean
            msg.send answer
    else
      msg.send "HUBOT_WOLFRAM_APPID is undefined"
