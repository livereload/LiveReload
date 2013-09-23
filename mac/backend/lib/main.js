(function() {
  var debug, shutdown, soa;

  debug = require('debug')('livereload:main');

  soa = require('livereload-soa');

  exports.run = function(argv) {
    var carrier;
    carrier = new soa.NodeStreamCarrier(process.stdin, process.stdout);
    require('./endpoint')(carrier);
    return carrier.on('end', shutdown);
  };

  shutdown = function() {
    process.stderr.write("Backend shutdown.\n");
    return process.exit(0);
  };

}).call(this);
