# Description:
#   Geolocate an IP Address
#
# Dependencies:
#   "lodash": "^4.17.15"
#
# Configuration:
#   MAXMIND_API_USER_ID
#   MAXMIND_API_LICENSE_KEY
#
# Notes:
#   None
#
# Commands:
#   hubot geolocate <ip> - Geolocates IP
#
# Authors:
#   Scott J Roberts - @sroberts
#   3ch01c

_ = require 'lodash'

module.exports = (robot) ->
  api_url = 'https://geoip.maxmind.com/geoip/v2.1/city'

  robot.respond /geo(locate)? ((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]))$/i, (msg) ->
    ip = msg.match[2]
    url = "#{api_url}/#{ip}"

    robot.http(url)
      .auth("#{process.env.MAXMIND_API_USER_ID}:#{process.env.MAXMIND_API_LICENSE_KEY}")
      .get() (err, res, body) ->
        if err
          console.log err
          msg.send err
        else
          console.log entity
          entity = JSON.parse(body)
          if (entity.error)
            response = entity.error
          else
            response = """Geolocation Result for #{ip}
                       ---------------------------
                       Entity: #{entity.traits.organization}
                       Location: #{entity.city.names.en}, #{entity.subdivisions[0].names.en} #{entity.country.names.en} | [OSM](https://openstreetmap.org/?mlat=#{entity.location.latitude}&mlon=#{entity.location.longitude}#map=15/#{entity.location.latitude}/#{entity.location.longitude}?m)
                       Domain: [#{entity.traits.domain}](#{entity.traits.domain})
                       ISP: #{entity.traits.isp}
                       """
          msg.send response
