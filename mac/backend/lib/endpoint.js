(function() {
  var soa;

  soa = require('livereload-soa');

  module.exports = function(carrier) {
    var endpoint, endpoints, muxer, _i, _len;
    muxer = soa.createMuxer(carrier);
    endpoints = [];
    endpoints.push(require('livereload-service-dummy'));
    endpoints.push(require('livereload-service-server'));
    endpoints.push(require('livereload-service-reloader'));
    for (_i = 0, _len = endpoints.length; _i < _len; _i++) {
      endpoint = endpoints[_i];
      endpoint(muxer);
    }
    return muxer;
  };

}).call(this);
