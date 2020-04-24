// Description:
// A hubot script to perform speedtests (of the machine/network hosting hubot)
//
// Dependencies:
//   "speedtest-net": "^1.2.6"
//
//
// Commands:
//   hubot run speedtest - returns internet speedtest results
//
// Author:
//   latrokles

const speedTest = require("speedtest-net");

module.exports = function (robot) {
  robot.respond(/run speedtest/i, (msg) => {
    msg.send("running connection speedtest...");
    // instantiate our speedtest
    const test = speedTest({ maxTime: 5000 });

    test.on("data", (results) => {
      const speed = results.speeds;
      let output = `here are the speed test results:\n`;
      output += `**speeds**\n----------\n`;
      output += `DOWNLOAD: ${speed.download} Mbps\n`;
      output += `UPLOAD:   ${speed.upload} Mbps`;

      msg.reply(output);
    });

    test.on("error", (error) => {
      msg.reply("There was an error running the speed test:\n", error);
    });
  });
};
