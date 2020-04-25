// Description
//   Test internet speed
//
// Dependencies:
//   "fast-speedtest-api": "^0.3.2"
//
// Configuration:
//   None
//
// Notes:
//   None
//
// Commands:
//   speedtest
//
// Author:
//   3ch01c

const FastSpeedtest = require("fast-speedtest-api");

FAST_API_KEY = process.env.FAST_API_KEY;
HTTP_PROXY = process.env.HTTP_PROXY;

module.exports = function (robot) {
  robot.respond(/speedtest$/i, (msg) => {
    msg.send("running speedtest...");
    let speedtest = new FastSpeedtest({
      token: FAST_API_KEY, // required
      verbose: false, // default: false
      timeout: 10000, // default: 5000
      https: false, // default: true
      urlCount: 5, // default: 5
      bufferSize: 8, // default: 8
      unit: FastSpeedtest.UNITS.Mbps, // default: Bps
      proxy: HTTP_PROXY, // default: undefined
    });

    speedtest
      .getSpeed()
      .then((s) => {
        msg.reply(`Download: ${s} Mbps`);
      })
      .catch((e) => {
        msg.reply(e.message);
      });
  });
};
