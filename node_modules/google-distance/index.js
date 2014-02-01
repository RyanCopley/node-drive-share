var qs = require('querystring'),
	http = require('http');
exports.get = function(args, callback) {
	var options = {
		index: args.index || null,
		origins: args.origin,
		destinations: args.destination,
		mode: args.mode || 'driving',
		units: args.units || 'imperial',
		language: args.language || 'en',
		avoid: args.avoid || null,
		sensor: args.sensor || false
	};

	if (!options.origins) {return callback(new Error('Argument Error: Origin is invalid'))}
	if (!options.destinations) {return callback(new Error('Argument Error: Destination is invalid'))}
		
	request(options, function(err, result) {
		if (err) {
			callback(err);
			return;
		}
		var data = result;
		if (data.status != 'OK') {
			callback(new Error('Status error: ' + data.status));
			return;
		}
		var d = {
			index: options.index,
			distance: data.rows[0].elements[0].distance.text,
			duration: data.rows[0].elements[0].duration.text,
			origin: data.origin_addresses[0],
			destination: data.destination_addresses[0],
			mode: options.mode,
			units: options.units,
			language: options.language,
			avoid: options.avoid,
			sensor: options.sensor
		};
		return callback(null, d);
	});	
}


var request = function(options, callback) {
	var httpOptions = {
	  	host: 'maps.googleapis.com',
	  	path: '/maps/api/distancematrix/json?' + qs.stringify(options)
	};

	var requestCallback = function(res) {
	  	var json = '';

	  	res.on('data', function (chunk) {
	    	json += chunk;
	    	callback(null, JSON.parse(json));
	  	});
	}	

	var req = http.request(httpOptions, requestCallback);
	req.on('error', function(err) {
 	 	callback(new Error('Request error: ' + err.message));
	});
	req.end();
}