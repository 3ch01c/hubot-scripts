// Description:
// A hubot script to perform speedtests (of the machine/network hosting hubot)
//
// Dependencies:
//   "speedtest-net": "^1.2.6"
//
// Configuration:
//   None
//
// Notes:
//   None
//
// Commands:
//   hubot run speedtest - returns internet speedtest results
//
// Author:
//   latrokles

"use strict";

const speedTest = require("speedtest-net");

module.exports = function (robot) {
  robot.respond(/speedtest/i, (msg) => {
    msg.send("running connection speedtest...");
    // instantiate our speedtest
    speedTest({
      acceptLicense: true,
      acceptGdpr: true,
    }).then(
      (results) => {
        robot.logger.debug(results);
        let output = `here are the speed test results:\n`;
        output += `server:   ${results.server.name} (${results.server.location})`;
        output += `ping:     ${results.ping.latency} ms\n`;
        output += `jitter:   ${results.ping.jitter} ms\n`;
        output += `download: ${results.download.bandwidth / 1000000} Mbps\n`;
        output += `upload:   ${speed.upload.bandwidth / 1000000} Mbps`;
        msg.reply(output);
      },
      (err) => {
        msg.reply(err.message);
      }
    );
  });
};
