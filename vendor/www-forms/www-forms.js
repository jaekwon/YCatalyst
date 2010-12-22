/*
Copyright (c) 2009 Hagen Overdick

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

function decode(token) {
  return decodeURIComponent(token.replace(/\+/g, " "));
}

function parseToken(token) {
  return token.split("=").map(decode);
}

function internalSetValue(target, key, value, force) {
  var arrayTest = key.match(/(.+?)\[(.*)\]/);
  if (arrayTest) {
    target = (target[arrayTest[1]] = target[arrayTest[1]] || []);
    target = target[arrayTest[2]] = value;
  } else {
    target = (target[key] = force ? value : target[key] || value);
  }
  return target;
}

function setValue(target, key, value) {
  var subkeys = key.split(".");
  var valueKey = subkeys.pop();

  for (var ii = 0; ii < subkeys.length; ii++) {
    target = internalSetValue(target, subkeys[ii], {}, false);
  }

  internalSetValue(target, valueKey, value, true);
}

exports.decodeForm = function(data) {
  var result = {};
  if (data && data.split) {
    data.split("&").map(parseToken).forEach(function(token) {
      setValue(result, token[0], token[1]);
    })
  }
  return result;
}
