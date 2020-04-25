# Description:
#   Dictionary definitions with the Wordnik API. 
#
# Dependencies:
#   None
#
# Configuration:
#   WORDNIK_API_KEY
#
# Notes:
#   You'll need an API key from http://developer.wordnik.com/
#   FIXME This should be merged with word-of-the-day.coffee
#
# Commands:
#   hubot define <word> - Grabs a dictionary definition of a word.
#   hubot pronounce <word> - Links to a pronunciation of a word.
#   hubot spell <word> - Suggests correct spellings of a possible word.
#   hubot bigram <word> - Grabs the most frequently used bigram phrases containing this word
#
# Author:
#   Aupajo
#   markpasc

WORDNIK_API_KEY = process.env.WORDNIK_API_KEY

module.exports = (robot) ->
  # Word definition
  robot.respond /define (.*)/i, (msg) ->
    word = msg.match[1]
    
    fetch_wordnik_resource(msg, word, 'definitions', {}) (err, res, body) ->
      definitions = JSON.parse(body)
      if definitions.length == 0 or res.statusCode == 404
        msg.send "No definitions for \"#{word}\" found."
      else
        reply = "Definitions for \"#{word}\":\n"
        lastSpeechType = null
        
        definitions = definitions.forEach (def) ->
          # Show the part of speech (noun, verb, etc.) when it changes
          if def.partOfSpeech != lastSpeechType
            reply += " (#{def.partOfSpeech})\n" if def.partOfSpeech != undefined

          # Track the part of speech
          lastSpeechType = def.partOfSpeech

          # Add the definition
          reply += "  - #{def.text}\n"
        
        msg.send reply

  # Pronunciation
  robot.respond /(pronounce|enunciate) (.*)/i, (msg) ->
    word = msg.match[3]
    
    fetch_wordnik_resource(msg, word, 'audio', {}) (err, res, body) ->
        pronunciations = JSON.parse(body)
      
        if pronunciations.length == 0
          msg.send "No pronounciation for \"#{word}\" found."
        else
          pronunciation = pronunciations[0]
          msg.send pronunciation.fileUrl

  robot.respond /spell (.*)/i, (msg) ->
    word = msg.match[1]

    fetch_wordnik_resource(msg, word, '', {includeSuggestions: 'true'}) (err, res, body) ->
      robot.logger.debug body
      wordinfo = JSON.parse(body)
      if wordinfo.canonicalForm
        msg.send "\"#{word}\" is a word."
      else if not wordinfo.suggestions
        msg.send "No suggestions for \"#{word}\" found."
      else
        list = wordinfo.suggestions.join(', ')
        msg.send "Suggestions for \"#{word}\": #{list}"

  # Bigrams
  robot.respond /bigram (.*)/i, (msg) ->
    word = msg.match[1]
      
    fetch_wordnik_resource(msg, word, 'phrases', {}) (err, res, body) ->
      phrases = JSON.parse(body)
      
      if phrases.length == 0
        msg.send "No bigrams for \"#{word}\" found."
      else
        reply = "Bigrams for \"#{word}\":\n"
        
        phrases = phrases.forEach (phrase) ->
          if phrase.gram1 != undefined and phrase.gram2 != undefined
            reply += "#{phrase.gram1} #{phrase.gram2}\n"
        
        msg.send reply

  fetch_wordnik_resource = (msg, word, resource, query, callback) ->
    # FIXME prefix with HUBOT_ for
    if process.env.WORDNIK_API_KEY == undefined
      msg.send "Missing WORDNIK_API_KEY env variable."
      return
    
    query.api_key = WORDNIK_API_KEY
      
    msg.http("http://api.wordnik.com/v4/word.json/#{word}/#{resource}")
      .query(query)
      .get(callback)