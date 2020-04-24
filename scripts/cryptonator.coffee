# Description
#   hubot script for looking up cryptocurriencies
#
# Commands:
#   hubot cryptocurrency BASE TARGET - convert BASE to TARGET currency
#
# Author:
#   Jack Miner <3ch01c@gmail.com>

URI = 'https://api.cryptonator.com/api/ticker'

module.exports = (robot) ->
  robot.respond /(cryptocurrency|coin)[: ](convert )?(\w+)( \w+)?/i, (msg) ->
    dividend = msg.match[3]
    divisor = (msg.match[4] || 'usd').trim()
    uri = "#{URI}/#{dividend}-#{divisor}"
    #console.log(uri)
    msg.http(uri).get() (err, res, body) ->
      json = JSON.parse(body)
      if json.success
        #console.log json
        ticker = json.ticker
        msg.send "#{ticker.base} = #{ticker.target} #{ticker.price} (V #{ticker.volume}, Δ #{ticker.change})"
      else
        msg.send json.error
