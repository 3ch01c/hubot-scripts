const {
  URLSearchParamsWithArrayBrackets,
  URLSearchParamsWithArrayIndices
} = require("./URLSearchParams.js");

// https://stackoverflow.com/questions/39776819/function-to-normalize-any-number-from-0-1
function normalize(value, max, min = 0) {
  return Number(((value - min) / (max - min)).toFixed(2));
}

function getAsync(client) {
  return new Promise((resolve, reject) => {
    client.get()((err, res, body) => {
      if (err) {
        console.log(err);
        reject(err);
      } else if (res.statusCode == 200) {
        resolve(body);
      } else {
        reject(new Error(`Error code ${res.statusCode}`));
      }
    });
  });
}

module.exports = {
  URLSearchParamsWithArrayBrackets: URLSearchParamsWithArrayBrackets,
  URLSearchParamsWithArrayIndices: URLSearchParamsWithArrayIndices,
  normalize: normalize,
  getAsync: getAsync
};
