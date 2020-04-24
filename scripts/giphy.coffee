# Description:
#   A way to search images on giphy.com
#
# Configuration:
#   HUBOT_GIPHY_API_KEY
#
# Commands:
#   hubot gif me <query> - Returns an animated gif matching the requested search term.

API_KEY = process.env.HUBOT_GIPHY_API_KEY
BASE_URL = 'http://api.giphy.com/v1'

module.exports = (robot) ->
  robot.respond /(gif|giphy)( me)? (.*)/i, (msg) ->
    giphyMe msg, msg.match[3], (url) ->
      msg.send url

giphyMe = (msg, query, cb) ->
  endpoint = '/gifs/search'
  url = "#{BASE_URL}#{endpoint}"

  msg.http(url)
    .query
      q: query
      api_key: API_KEY
    .get() (err, res, body) ->
      console.log(res, body, err)
      response = undefined
      try
        response = JSON.parse(body)
        images = response.data
        if images.length > 0
          image = msg.random images
          cb image.images.original.url

      catch e
        response = undefined
        cb 'Error:', e

      return if response is undefined
