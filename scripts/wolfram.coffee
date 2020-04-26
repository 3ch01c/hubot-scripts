# Description:
#   Allows hubot to answer almost any question by asking Wolfram Alpha
#
# Dependencies:
#  None
#
# Configuration:
#   HUBOT_WOLFRAM_APPID - your app id
#
# Notes:
#   None
#
# Commands:
#   hubot wolfram <question> - Searches Wolfram Alpha for the answer to the question
#
# Author:
#   dhorrigan

module.exports = (robot) ->
  HUBOT_WOLFRAM_APPID = process.env.HUBOT_WOLFRAM_APPID?
  robot.respond /((Who|What|When|Where|Why|How|wolfram) (.+))$/i, (msg) ->
    try
      unless HUBOT_WOLFRAM_APPID?
        msg.reply "HUBOT_WOLFRAM_APPID is undefined"
      else
        input = msg.match[1]
        uri = "http://api.wolframalpha.com/v2/query?input=#{encodeURIComponent(input)}&format=image,plaintext&output=JSON&appid=#{encodeURIComponent(process.env.HUBOT_WOLFRAM_APPID)}"
        robot.http(uri).get() (err, response, body) ->
          if err?
            robot.logger.debug err
            msg.reply err.message
          else
            results = JSON.parse body;
            robot.logger.debug "wolfram results: #{JSON.stringify results, null, 2}"
            if results.queryresult.success
              answers = []
              results.queryresult.pods[1..].forEach (pod) ->
                answer = 
                """
                **#{pod.title}**
                #{pod.subpods.map((subpod) -> if subpod.plaintext.length > 0 then subpod.plaintext).join('\n')}
                """
                answers.push answer
              msg.reply answers.join "\n"
    catch e
      robot.logger.debug e
      msg.reply e.message