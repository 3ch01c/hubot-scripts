# Description:
#   Perspective API adapter (https://conversationai.github.io/)
#
# Dependencies:
#   None
#w
# Configuration:
#
# Commands:
#   hubot perspective:toxicity <TEXT> - get toxicity score for TEXT
#
# Author:
#   Jack Miner <3ch01c@gmail.com>
PERSPECTIVE_API_KEY = process.env.PERSPECTIVE_API_KEY
api_url = "https://commentanalyzer.googleapis.com/v1alpha1/"

module.exports = (robot) ->
  robot.respond /perspective(:toxicity)? (.+)$/i, (msg) ->
    text = msg.match[2].trim()
    data = comment:
            text: text
            languages: ["en"]
            requestedAttributes:
              TOXICITY: {}
    robot.http("#{api_url}comments:analyze?key=#{encodeURIComponent PERSPECTIVE_API_KEY}")
      .headers("Content-Type": "application/json")
      .post(data) (err, res, body) ->
        console.log(res)
        if res.statusCode is 200
          msg.send "#{JSON.parse(body).attributeScores.TOXICITY.summaryScore.value}"
        else
          msg.send "Error: Couldn't access #{api_url}. Error Message: #{err}. Status Code: #{res.statusCode}"
