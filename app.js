/**
 * Module dependencies.
 */
var express = require('express');
var routes = require('./routes');
var http = require('http');
var geocoder = require('geocoder');
var distance = require('google-distance');
var io = require('socket.io').listen(30001);
var mongoose = require('mongoose');
var fs = require('fs');

io.set('log level', 1); // reduce logging for Socket.IO
mongoose.connect('mongodb://localhost/drive');
var db = mongoose.connection;
db.on('error', console.error.bind(console, 'connection error:'));
db.once('open', function callback() {
    console.log("Connected to Mongo");
});

//DB Schema
var updateSchema = mongoose.Schema({
    lat: Number,
    lng: Number,
    spd: Number,
    time: {
        type: Date,
        default: (new Date)
    }
});
var Trip = mongoose.model('Trip', updateSchema);
var logFile = fs.createWriteStream('./log.log', {flags: 'a'}); //use {flags: 'w'} to open in write mode


var app = express();
app.set('port', process.env.PORT || 30000);
app.set('views', path.join(__dirname, 'views'));
app.use(express.logger({stream: logFile}));
app.use(express.json());
app.use(express.urlencoded());
app.use(express.methodOverride());
app.use(app.router);
app.use(express.static(path.join(__dirname, 'public')));


//Google Maps Distance Matrix Updating (36 seconds = 2500 per day, right under the limit at max load ... )
setInterval(calcDistance, 36000);
reset();

//New web clients connecting ...
io.sockets.on('connection', function (socket) {
    updateDirectionsWeb();
    if (totalDistance != 0) {
        console.log("Sending distance total" + totalDistance);
        socket.emit('distance', {
            "distance": totalDistance
        });
    }
    if (curDistance != 0) {
        sendDistance();
    }
	sendStatus();
    socket.on('updateplease', function (data) {
        if (latest != 0 && fromCoords != 0 && toCoords != 0) {
            var numberOfSockets = Object.keys(io.connected).length;
            post = latesttrip;

            var time = (latest.getTime() / 1000) + 40;
            var expire = (new Date).getTime() / 1000;
            if (time > expire) {
                socket.emit('location', {
                    "pos": post,
                    "num": numberOfSockets
                });
            } else {
                socket.emit('offline', {});
            }
        }
    });
});

app.get('/', function (req, res) {
    res.sendfile("views/index.html");
});

app.get("/start", function (req, res) {
    reset();
    io.sockets.emit('online', {});
});

app.get("/kill", function (req, res) {
    reset();
    updateDirectionsWeb();
    io.sockets.emit('offline', {});
    res.send({});

});

app.get("/setaddr", function (req, res) {
    // Geocoding
    curDistance = 0;
    totalDistance = 0;
    var from = res.req.query.from;
    var to = res.req.query.to;

    //Geocode the "from"
    geocoder.geocode(from, function (err, data) {
        var lat = data.results[0].geometry.location.lat;
        var lng = data.results[0].geometry.location.lng;
        fromCoords = {
            "lat": lat,
            "lng": lng
        };

        // ...Then the "to"
        geocoder.geocode(to, function (err, data) {
            var lat = data.results[0].geometry.location.lat;
            var lng = data.results[0].geometry.location.lng;
            toCoords = {
                "lat": lat,
                "lng": lng
            };

            //Ask for an update
            updateDirectionsWeb();
        });
    });


    res.send({});

});

app.get("/update", function (req, res) {

    var lat = res.req.query.lat;
    var lng = res.req.query.lng;
    var spd = res.req.query.spd;

    var trip = new Trip({
        lat: lat,
        lng: lng,
        spd: spd
    });
    latest = new Date;
    latesttrip = trip;
    trip.save(function (err, x) {
        if (err) {
            console.log("Error saving row");
        }
    });

    res.send({});
});

function updateDirectionsWeb() {
    if (fromCoords != 0 && toCoords != 0) {

        if (totalDistance == 0) { // Only do this if we do not already have it. The GMaps API is expensive.
            distance.get({
                    origin: fromCoords.lat + "," + fromCoords.lng,
                    destination: toCoords.lat + "," + toCoords.lng
                },
                function (err, data) {
                    if (err) {
                        console.error(err);
                        return;
                    }
                    console.log("Total Distance Found: " + data.distance);
                    totalDistance = data.distance;
                    io.sockets.emit('distance', {
                        "distance": totalDistance
                    });
                });
        }

        io.sockets.emit('directions', {
            "from": fromCoords,
            "to": toCoords
        });

    } else {
        // 0/0 = "offline"
        io.sockets.emit('directions', {
            "from": 0,
            "to": 0
        });
    }
}

function reset() {
    //Variables
    latest = 0;
    fromCoords = 0;
    toCoords = 0;
    totalDistance = 0;
    curDistance = 0;
    latesttrip = 0;
}

function calcDistance() {
    if (latest != 0 && toCoords != 0) {

        distance.get({
                origin: latesttrip.lat + "," + latesttrip.lng,
                destination: toCoords.lat + "," + toCoords.lng
            },
            function (err, data) {
                if (err) {
                    console.error(err);
                    return;
                }
                curDistance = data.distance;
                sendDistance();
            });
    }
}

function sendDistance() {
    console.log("Sending Current Distance:" + curDistance);
    io.sockets.emit('currentDistance', {
        "distance": curDistance
    });
}

function sendStatus(){
	
    if (fromCoords != 0 && toCoords != 0) {
    	
	    io.sockets.emit('online', {});
    }else{
    	io.sockets.emit('offline', {});
    }
}

http.createServer(app).listen(app.get('port'), function () {
    console.log('Express server listening on port ' + app.get('port'));
});
