# Description:
#   Trac interaction script
#
# Dependencies:
#   "xml2js": "0.1.14",
#   "moment-timezone": "^0.5.9"
#
# Configuration:
#   HUBOT_TRAC_URL: Base URL to Trac instance, without trailing slash eg: https://myserver.com/trac
#   HUBOT_TRAC_USER: Trac username (uses HTTP basic authentication)
#   HUBOT_TRAC_PASSWORD: Trac password
#
# Optional Configuration:
#   HUBOT_TRAC_JSONRPC: "true" to use the Trac http://trac-hacks.org/wiki/XmlRpcPlugin.
#                       Requires jsonrpc to be enabled in the plugin. Default to "true".
#   HUBOT_TRAC_SCRAPE: "true" to use HTTP scraping to pull information from Trac.
#                      Defaults to "true".
#   HUBOT_TRAC_LINKDELAY: number of seconds to not show a link for again after it's been
#                         mentioned once. This helps to cut down on noise from the bot.
#                         Defaults to 30.
# Commands:
#   hubot trac:ticket (#|URL) - Show details about Trac ticket # or URL
#
# Notes:
#   Tickets pull from jsonrpc (if enabled), then scraping (if enabled), and otherwise just put a link
#   Revisions pull from scraping (if enabled), and otherwise just post a link. (There are no xmlrpc methods
#   for changeset data).
#
# Author:
#   gregmac

#fs = require 'fs'  #todo: load jquery from filesystem
jsdom = require('jsdom')
jquery = require('jquery')
moment = require('moment-timezone')

DATE_PARSE_FORMAT = "YYYY-MM-DDTHH:mm:ss"
DATE_FORMAT = "YY/MM/DD HH:mm:ss Z"
POWER = 'usoc'

# keeps track of recently displayed issues, to prevent spamming
class RecentIssues
  constructor: (@maxage) ->
    @issues = []

  cleanup: ->
    for issue,time of @issues
      age = Math.round(((new Date()).getTime() - time) / 1000)
      if age > @maxage
        #console.log 'removing old issue', issue
        delete @issues[issue]
    return

  contains: (issue) ->
    @cleanup()
    @issues[issue]?

  add: (issue,time) ->
    time = time || (new Date()).getTime()
    @issues[issue] = time

module.exports = (robot) ->
  # if trac json-rpc is available to use for retreiving tickets (faster)
  useJsonrpc = process.env.HUBOT_TRAC_JSONRPC || false

  # if screen scraping can be used for tickets/changesets. If both jsonrpc and scrape are off, only a link gets posted
  useScrape = process.env.HUBOT_TRAC_SCRAPE || true

  # how long (seconds) to wait between repeating the same link
  linkdelay = process.env.HUBOT_TRAC_LINKDELAY || 30

  recentlinks = new RecentIssues linkdelay

  # scrape a URL
  # selectors: an array of jquery selectors
  # callback: function that takes (error,response)
  scrapeHttp = (msg, url, user, pass, selectors, callback) ->
    authdata =
    console.log "Sending message to #{url} using #{user}:#{pass}"
    msg.http(url).
      headers(Authorization: 'Basic ' + new Buffer(user+':'+pass).toString('base64'))
      .get() (err, res, body) ->
        # http errors
        if err
          callback err, body
          return
        console.log res.statusCode
        switch res.statusCode
          when 403
            callback 'Authentication failed'
          else
            jsdom.env body, [jquery], (errors, window) ->
              # use jquery to run selector and return the elements
              $ = jquery(window)
              results = ($(selector).text().trim() for selector in selectors)
              callback null, results

  # call a json-rpc method
  # callback is passed (error,response)
  # borrowed heavily from https://github.com/andyfowler/node-jsonrpc-client/
  jsonRpc = (msg, url, user, pass, method, params, callback) ->
    authdata = new Buffer(user+':'+pass).toString('base64')
    console.log authdata

    jsonrpcParams =
      jsonrpc: '2.0'
      id:      (new Date).getTime()
      method:  method
      params:  params

    console.log url, JSON.stringify jsonrpcParams
    msg.http(url)
      .header('Authorization', 'Basic ' + authdata)
      .header('Content-Type', 'application/json')
      .post(JSON.stringify jsonrpcParams) (err, res, body) ->
        # http errors
        if err
          callback err, body
          return

        # response json parse errors
        try
          decodedResponse = JSON.parse body
        catch decodeError
          callback 'Could not decode JSON response', body
          return

        #json-rpc errors
        if decodedResponse.error
          errorMessage = " #{decodedResponse.error.message}"
          callback errorMessage, decodedResponse.error.data
          return

        callback null, decodedResponse.result

  # fetch a ticket using json-rpc
  ticketRpc = (msg, ticket) ->
    jsonRpc msg, process.env.HUBOT_TRAC_URL+'/login/jsonrpc', process.env.HUBOT_TRAC_USER, process.env.HUBOT_TRAC_PASSWORD,
      'ticket.get', [ticket],
      (err,response) ->
        if err
          console.log 'Error retrieving trac ticket', ticket, err
          return

        ticketid = response[0]
        dateCreated = moment(response[1].__jsonclass__[1], DATE_PARSE_FORMAT)
        dateUpdated = moment(response[2].__jsonclass__[1], DATE_PARSE_FORMAT)
        issue = response[3]

        if !ticketid
          console.log 'Error understanding trac response', ticket, response
          return

        url = process.env.HUBOT_TRAC_URL+"/ticket/"+ticketid
        msg.send "#{url}\n#### #{issue.summary}\nOwner: #{issue.owner}\nStatus: #{issue.status}\nCreated: #{dateCreated.format DATE_FORMAT}\nLast updated: #{dateUpdated.format DATE_FORMAT}\nJC3 ticket: #{issue.jc3_ticket}"

  # fetch a ticket using json-rpc
  queryRpc = (msg, query) ->
    jsonRpc msg, process.env.HUBOT_TRAC_URL+'/login/jsonrpc', process.env.HUBOT_TRAC_USER, process.env.HUBOT_TRAC_PASSWORD,
      'ticket.query', {qstr: query},
      (err,response) ->
        if err
          console.log 'Error retrieving trac ticket', query, err
          return

        console.log response

        ticketid = response[0]
        dateCreated = moment(response[1].__jsonclass__[1], DATE_PARSE_FORMAT)
        dateUpdated = moment(response[2].__jsonclass__[1], DATE_PARSE_FORMAT)
        issue = response[3]

        if !ticketid
          console.log 'Error understanding trac response', ticket, response
          return

        url = process.env.HUBOT_TRAC_URL+"/ticket/"+ticketid
        msg.send "#{url}\n#### #{issue.summary}\nOwner: #{issue.owner}\nStatus: #{issue.status}\nCreated: #{dateCreated.format DATE_FORMAT}\nLast updated: #{dateUpdated.format DATE_FORMAT}\nJC3 ticket: #{issue.jc3_ticket}"

  # fetch a ticket using http scraping
  ticketScrape = (msg, ticket) ->

    scrapeHttp  msg, process.env.HUBOT_TRAC_URL+'/ticket/'+ticket, process.env.HUBOT_TRAC_USER, process.env.HUBOT_TRAC_PASSWORD,
      ['#trac-ticket-title .summary', 'td[headers=h_owner]', '#trac-ticket-title .status', 'td[headers=h_milestone]']
      (err, response) ->
        if (err)
          msg.send err
          return
        console.log 'scrape response', response
        url = process.env.HUBOT_TRAC_URL+"/ticket/"+ticket
        msg.send "Trac \##{ticket}: #{response[0]}. #{response[1]} / #{response[2]}, #{response[3]} #{url}"


  # fetch a changeset using http scraping
  changesetScrape = (msg, revision) ->
    scrapeHttp  msg, process.env.HUBOT_TRAC_URL+'/changeset/'+revision, process.env.HUBOT_TRAC_USER, process.env.HUBOT_TRAC_PASSWORD,
      ['#content.changeset dd.message', '#content.changeset dd.author', '#content.changeset dd.time']
      (err, response) ->
        if (err)
          msg.send err
          return
        console.log 'scrape response', response
        url = process.env.HUBOT_TRAC_URL+"/changeset/"+revision
        author = response[1]
        time = response[2].replace(/[\n ]{2,}/,' ')
        message = response[0]
        msg.send "Trac r#{revision}: #{author} #{time} #{url}"
        msg.send line for line in message.split("\n")

  # fetch ticket information using scraping or jsonrpc
  fetchTicket = (res) ->
    unless robot.auth.hasPower res.envelope.user, POWER
      res.send "Sorry, you are unauthorized to use this command."
      return
    for matched in res.match
      ticket = (matched.match /\d+/)[0]
      linkid = res.message.user.room+'#'+ticket
      if !recentlinks.contains linkid
        recentlinks.add linkid
        console.log 'trac ticket link', ticket

        if useJsonrpc
          ticketRpc res, ticket
        else if useScrape
          ticketScrape res, ticket
        else
          res.send "Trac \##{ticket}: #{process.env.HUBOT_TRAC_URL}/ticket/#{ticket}"

  # listen for ticket numbers
  robot.respond /trac:ticket (\d+)$/i, fetchTicket
  robot.respond (new RegExp("trac:ticket #{process.env.HUBOT_TRAC_URL}/ticket/([0-9]+)", 'i')), fetchTicket

  queryTicket = (res) ->
    unless robot.auth.hasPower res.envelope.user, POWER
      res.send "Sorry, you are unauthorized to use this command."
      return
    query = res.match[1].trim()
    subj = res.match[2].trim()
    op = res.match[3]
    val = res.match[4]
    linkid = res.message.user.room+"#"+query
    if !recentlinks.contains linkid
      recentlinks.add linkid
      if useJsonrpc
        queryRpc res, query
    return

  robot.respond /trac:query(( [a-z0-9_]+)([=><])(.+))+$/i, queryTicket

  # listen for changesets
  handleChangeset = (res) ->
    role = 'usoc'
    unless robot.auth.hasPower res.envelope.user, POWER
      res.send "Sorry, you are unauthorized to use this command."
      return
    for matched in res.match
      revision = (matched.match /\d+/)[0]

      linkid = res.message.user.room+'r'+revision
      if !recentlinks.contains linkid
        recentlinks.add linkid
        console.log 'trac changeset link', revision

        # note, trac has no API methods for changesets, all we can do is scrape
        if useScrape
          changesetScrape res, revision
        else
          res.send "Trac r#{revision}: #{process.env.HUBOT_TRAC_URL}/changeset/#{revision}"

  #robot.respond /trac:changeset (\d+)$/i, handleChangeset
