# Description
#   hubot script for looking up cryptocurrencies
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Notes:
#   None
#
# Commands:
#   hubot (crypto)currency <source> <target> - convert source to target currency
#
# Author:
#   3ch01c

module.exports = (robot) ->
  URI = 'https://api.cryptonator.com/api/ticker'

  robot.respond /((crypto)?currency|coin) (\w+)( (\w+))?/i, (msg) ->
    dividend = msg.match[3]
    divisor = msg.match[5] || 'usd'
    uri = "#{URI}/#{dividend}-#{divisor}"
    #console.log(uri)
    robot.http(uri).get() (err, res, body) ->
      json = JSON.parse body 
      if json.success
        ticker = json.ticker
        robot.logger.debug ticker
        msg.send "#{ticker.base} = #{ticker.target} #{ticker.price} (V #{ticker.volume}, Δ #{ticker.change})"
      else
        msg.send json.error
