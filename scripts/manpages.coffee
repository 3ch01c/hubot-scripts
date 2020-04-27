# Description
#   TLDR Pages API Client for Hubot
#   https://github.com/tldr-pages/tldr
#
# Configuration:
#   None
#
# Commands:
#   hubot man search <command> - Returns tldr man page / examples for <command>
#
# Notes:
#   None
#
# Author:
#   MrSaints

TLDR_INDEX_API = "https://api.github.com/repos/tldr-pages/tldr-pages.github.io/contents/assets/index.json"
TLDR_CMD_API = "https://api.github.com/repos/tldr-pages/tldr/contents/pages"

module.exports = (robot) ->
    _commands = []
    robot.http(TLDR_INDEX_API)
        .get() (err, httpRes, body) ->
            if err or httpRes.statusCode isnt 200
                return robot.logger.error "hubot-manpages: #{err}"
            try
                decoded = new Buffer(JSON.parse(body).content, "base64").toString("ascii")
                _commands = JSON.parse(decoded).commands
            catch error
                return robot.logger.error "hubot-manpages: #{error}"

    _commandExists = (cmd) ->
        return false unless _commands.length > 0
        # TODO: Implement binary search?
        return _command for _command in _commands when _command.name is cmd
        false

    _getCommand = (res, cmd, cb) ->
        url = [TLDR_CMD_API, cmd.platform[0], "#{cmd.name}.md"].join('/')
        res.http(url)
            .get() (err, httpRes, body) =>
                console.log httpRes.statusCode
                if err or httpRes.statusCode isnt 200
                    res.reply "An error occurred while attempting to process your request."
                    return res.robot.logger.error "hubot-manpages: #{err}"
                try
                    data = JSON.parse(body)
                    decoded = new Buffer(data.content, "base64").toString("ascii")
                    cb data.html_url, decoded
                catch error
                    return robot.logger.error "hubot-manpages: #{error}"

    robot.respond /man (.+)/i, id: "manpages.search", (res) ->
        cmd = res.match[1].trim()
        if command = _commandExists(cmd)
            _getCommand res, command, (link, content) =>
                res.send content
                res.reply "Original `#{command.name}` (#{command.platform[0]}) tldr man page: #{link}"
            return
        res.reply "The command you have entered, `#{cmd}`, cannot be found in tldr pages."
