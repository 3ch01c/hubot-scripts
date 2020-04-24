# Description:
#   Track coop transactions
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot coop:buy THING - buy a thing
#   hubot coop:deposit AMOUNT - deposit money into the coop balance
#   hubot coop:withdraw AMOUNT - withdraw money from coop balance
#   hubot coop:inventory THING - show inventory of thing (if thing omitted, show inventory of everything)
#   hubot coop:balance PERSON - show person's balance (if person omitted, show sender's balance)
#   hubot coop:restock THING QTY - add thing
#   hubot coop:price THING PRICE - price thing
#   hubot coop:remove THING - remove thing
#
# Author:
#   3ch01c

module.exports = (robot) ->
  class Coop

    constructor: (@robot) ->
      @robot.brain.on 'loaded', =>
        @cache = @robot.brain.data.coop or items: {}, patrons: {}

    restock: (item, count, price) ->
      @cache.items[item] ?= count: 0, price: 0
      if count
        @cache.items[item].count += count
      if price
        @cache.items[item].price = price
      @robot.brain.data.coop = @cache

    remove: (item) ->
      delete @cache.items[item]
      @robot.brain.data.coop = @cache

    buy: (item, patron) ->
      # decrement item quantity
      @cache.items[item] ?= count: 0, price: 0 # TODO: send a message this needs to be restocked
      @cache.items[item].count-- # TODO: send a message this needs to be restocked if low
      # decrement cost of item from patron's balance
      @cache.patrons[patron] ?= balance: 0 # TODO: send a message to patron they need to deposit money
      @cache.patrons[patron].balance -= @cache.items[item].price
      # TODO: warn patron if their balance is low
      @robot.brain.data.coop = @cache

    deposit: (money, patron) ->
      # add money to patron balance
      @cache.patrons[patron] ?= balance: 0
      @cache.patrons[patron].balance += money
      @robot.brain.data.coop = @cache

    withdraw: (money, patron) ->
      @cache.patrons[patron] ?= balance: 0
      @cache.patrons[patron].balance -= money # TODO: send a message if this patron needs to deposit money
      @robot.brain.data.coop = @cache

    getItem: (item) ->
      @cache.items[item] ?= count: 0, price: 0
      @cache.items[item] # TODO: handle missing items
      # TODO: get list of items

    getPatron: (patron) ->
      @cache.patrons[patron] ?= balance: 0
      @cache.patrons[patron] # TODO: handle missing patrons
      # TODO: get list of all patrons

    confirm: (msg) ->
      if @robot.adapter.client?.web?.reactions?
        @robot.adapter.client.web.reactions.add('ok_hand', {channel: msg.message.room, timestamp: msg.message.id})
      else
        msg.send("OK!")

  coop = new Coop robot

  robot.respond /coop[: ]buy( a|an)? (.+)/i, (res) ->
    item = res.match[2].toLowerCase()
    patron = res.message.user.name
    coop.buy item, patron
    res.send "#{item} coming right up! Your remaining balance is $#{coop.getPatron(patron).balance.toFixed(2)}"

  robot.respond /coop[: ]deposit \-?\$?(\d*\.?\d+)/i, (res) ->
    money = Number(res.match[1])
    patron = res.message.user.name
    coop.deposit(money, patron)
    res.send "Your balance is $#{coop.getPatron(patron).balance.toFixed(2)}"

  robot.respond /coop[: ]withdraw \$?(\d*\.?\d+)/i, (res) ->
    money = Number(res.match[1])
    patron = res.message.user.name
    coop.withdraw(money, patron)
    res.send "Your balance is $#{coop.getPatron(patron).balance.toFixed(2)}"

  robot.respond /coop[: ]restock (.+) (\d+)/i, (res) ->
    item = res.match[1].toLowerCase()
    count = Number(res.match[2])
    coop.restock(item, count, undefined)
    res.send "Stock of #{item} remaining: #{coop.getItem(item).count}"

  robot.respond /coop[: ]price (.+) \$?(\d*\.?\d+)/i, (res) ->
    item = res.match[1].toLowerCase()
    price = Number(res.match[2])
    coop.restock(item, undefined, price)
    res.send "#{item} price: $#{coop.getItem(item).price.toFixed(2)}"

  robot.respond /coop[: ]remove (.+)/i, (res) ->
    item = res.match[1].toLowerCase()
    coop.remove(item)
    res.send "#{item} removed from inventory."

  robot.respond /coop[: ]inventory( .+)?/i, (res) ->
    if res.match[1]
      item = res.match[1].toLowerCase().trim()
      res.send "#{coop.getItem(item).count} #{item}(s) remaining @ $#{coop.getItem(item).price.toFixed(2)} each"
    else
      res.send "Snack Co-op"
      res.send "======================="
      res.send "#{name} $#{item.price.toFixed(2)}" for name, item of coop.cache.items

  robot.respond /coop[: ]balance( (.+))?/i, (res) ->
    if res.match[2]
      patron = res.match[2].toLowerCase()
    else
      patron = res.message.user.name
    res.send "#{patron}'s remaining balance is $#{coop.getPatron(patron).balance.toFixed(2)}"
