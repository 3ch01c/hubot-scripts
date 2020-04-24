// Description:
//   Make hubot upright a table
//
// Dependencies:
//   None
//
// Configuration:
//   None
//
// Commands:
//   None
//
// Notes:
//   None
//
// Author:
//   3ch01c

module.exports = (robot) => {
  robot.hear(/┻━┻/i, function (msg) {
    return msg.send("┬─┬ ノ( ^_^ノ)");
  });
};
