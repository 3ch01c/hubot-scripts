"use strict";

// Description
//   hubot scripts for diagnosing hubot
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Notes:
//   None
//
// Commands:
//   hubot ping - Reply with pong
//   hubot adapter - Reply with the adapter
//   hubot echo <text> - Reply back with <text>
//   hubot time - Reply with current time
//
// Author:
//   Josh Nichols <technicalpickles@github.com>
//   3ch01c

module.exports = function (robot) {
  robot.respond(/PING$/i, (msg) => {
    let responses = [
      "PONG, sucka!",
      "PONG",
      "PONG",
      "PONG",
      "PONG",
      "PONG",
      "PONG",
      "PONG",
    ];
    msg.send(msg.random(responses));
  });

  robot.respond(/ADAPTER$/i, (msg) => {
    msg.send(robot.adapterName);
  });

  robot.respond(/ECHO (.*)$/i, (msg) => {
    msg.send(msg.match[1]);
  });

  robot.respond(/TIME$/i, (msg) => {
    msg.send(`Server time is: ${new Date()}`);
  });
};
