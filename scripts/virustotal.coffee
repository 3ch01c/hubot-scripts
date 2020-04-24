# Description:
#   Check VirusTotal for Malware
#
# Dependencies:
#   None
#
# Configuration:
#   VIRUSTOTAL_API_KEY - Sign up at https://www.virustotal.com/en/documentation/public-api/
#
# Commands:
#   hubot virustotal [hash <hash>|url <url>|ip <ip>] - Searches VirusTotal for a hash, url, or ip address
#
# Author:
#   Scott J Roberts - @sroberts

VIRUSTOTAL_API_KEY = process.env.VIRUSTOTAL_API_KEY
vt_url = "https://www.virustotal.com/vtapi/v2"

vt_file_report_url = vt_url + "/file/report"
vt_url_report_url = vt_url + "/url/report"
vt_ip_report_url = vt_url + "/ip-address/report"

module.exports = (robot) ->

  robot.respond /v(irus)?t(otal)? ?(h(ash)?|u(rl)?|ip?) (.*)/i, (msg) ->

    if VIRUSTOTAL_API_KEY?
      console.log msg.match
      type = msg.match[3].toLowerCase()
      endpoint = vt_file_report_url
      if type.charAt(0) is "u"
        endpoint = vt_file_report_url
      else if type.charAt(0) is "i"
        endpoint = vt_ip_report_url
      val = msg.match[6].toLowerCase()
      data = "apikey=#{encodeURIComponent VIRUSTOTAL_API_KEY}&resource=#{encodeURIComponent val}"
      console.log "#{endpoint}/#{data}"

      if type.charAt(0) is "i"
        robot.http(endpoint)
        .query("apikey": VIRUSTOTAL_API_KEY, "ip": val)
        .get() (err, res, body) ->
          if res.statusCode is 200
            vt_json = JSON.parse body
            msg.send(JSON.stringify(vt_json))
      else
        robot.http(endpoint)
        .post(data) (err, res, body) ->
          if res.statusCode is 200
            vt_json = JSON.parse body
            msg.send(JSON.stringify(vt_json))
