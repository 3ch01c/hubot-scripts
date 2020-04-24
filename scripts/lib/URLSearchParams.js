"use strict";
// Other ways APIs implement URLSearchParams. Not my own, but I can't find the original source.
// https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams/URLSearchParams
// https://blog.bitsrc.io/using-the-url-object-in-javascript-5f43cd743804

function URLSearchParamsWithArrayBrackets(obj, prefix) {
  let str = [],
    p;
  for (p in obj) {
    if (obj.hasOwnProperty(p)) {
      let k = prefix ? prefix + "[]" : p,
        v = obj[p];
      str.push(
        v !== null && typeof v === "object"
          ? URLSearchParamsWithArrayBrackets(v, k)
          : encodeURIComponent(k) + "=" + encodeURIComponent(v)
      );
    }
  }
  return str.join("&");
}

function URLSearchParamsWithArrayIndices(obj, prefix) {
  let str = [],
    p;
  for (p in obj) {
    if (obj.hasOwnProperty(p)) {
      let k = prefix ? prefix + "[" + p + "]" : p,
        v = obj[p];
      str.push(
        v !== null && typeof v === "object"
          ? URLSearchParamsWithArrayIndices(v, k)
          : encodeURIComponent(k) + "=" + encodeURIComponent(v)
      );
    }
  }
  return str.join("&");
}

module.exports = {
  URLSearchParamsWithArrayBrackets: URLSearchParamsWithArrayBrackets,
  URLSearchParamsWithArrayIndices: URLSearchParamsWithArrayIndices
};
