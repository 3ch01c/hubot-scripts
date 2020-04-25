// Description:
//   Make hubot upright a table
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
//   None
//
// Author:
//   3ch01c

module.exports = (robot) => {
  robot.hear(/(┻━┻|unflip)/i, function (msg) {
    return msg.send("┬─┬ ノ( ^_^ノ)");
  });
};
