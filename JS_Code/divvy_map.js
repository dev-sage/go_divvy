 /* Creating Map */ 
var map = L.map("map", {zoomControl: false}).setView([41.891139, -87.626542], 12);
L.tileLayer('https://api.tiles.mapbox.com/v4/{mapid}/{z}/{x}/{y}.png?access_token={accessToken}', {
             attribution: "",
             maxZoom: 15,
             minZoom: 3,
             mapid: 'mapbox.dark',
             accessToken: 'pk.eyJ1IjoiZGV2LXNhZ2UiLCJhIjoiY2lrMW9yMXIwMzlyMHZnbHpwb3RrcnN2cyJ9.1nGy-0e-Xwg-kEyOvy5Isg'
            }).addTo(map);

function draw_route(polyline, alpha) {
	var decoded_path = L.Polyline.fromEncoded(polyline);
	var drawn_path = new L.Polyline(decoded_path.getLatLngs(), {
		snakingSpeed: 50, snakingPause: 0, color: "#1ac6ff", opacity: alpha, weight: 2.00 });

	//path_layer.addLayer(drawn_path);	
	//map.addLayer(path_layer);
	drawn_path.addTo(map).snakeIn();
	//drawn_path.addEventListener('snakeend', clear_path(this));
}

function clear_path(path) {
	map.removeLayer(path);
}

d3.csv("data/combo_lines.csv", function(error, data) {
	data.forEach(function(row) {
		row.count = +row.count;
		row.from_station_lng = +row.from_station_lng;
		row.to_station_lng= +row.to_station_lng;
		row.from_station_lat = +row.from_station_lat;
		row.to_station_lat = +row.to_station_lat;
		row.distance = +row.distance;
		row.time = +row.time;
	});

	var alpha_scale = d3.scale.linear()
		.domain([0.1, d3.max(data, function(row) { return row.count })])
		.range([0, 1]);

	setTimeout(data.forEach(function(row) { draw_route(row.polyline, alpha_scale(row.count)); }), 10000);


})