 /* Creating Map */ 
var map = L.map("map", {zoomControl: true}).setView([41.891139, -87.626542], 12);
L.tileLayer('https://api.tiles.mapbox.com/v4/{mapid}/{z}/{x}/{y}.png?access_token={accessToken}', {
             attribution: "",
             maxZoom: 15,
             minZoom: 11,
             mapid: 'mapbox.dark',
             accessToken: 'pk.eyJ1IjoiZGV2LXNhZ2UiLCJhIjoiY2lrMW9yMXIwMzlyMHZnbHpwb3RrcnN2cyJ9.1nGy-0e-Xwg-kEyOvy5Isg'
            }).addTo(map);

var path_layer = new L.layerGroup();
function draw_route(polyline, alpha, path_col, line_size, scatter_line) {
	var decoded_path = L.Polyline.fromEncoded(polyline);
	var drawn_path = new L.Polyline(decoded_path.getLatLngs(), {
		snakingSpeed: 50, snakingPause: 0, color: path_col, opacity: alpha, weight: line_size });

	//path_layer.addLayer(drawn_path);	
	//map.addLayer(path_layer);
	if(!scatter_line) drawn_path.addTo(map).snakeIn();
	if(scatter_line) {
		path_layer.addLayer(drawn_path);
		path_layer.addTo(map);
	}
	//drawn_path.addEventListener('snakeend', clear_path(this));
}

function remove_trip_path(path) {
	map.removeLayer(path_layer);
	path_layer = new L.layerGroup();
}

var data_g;
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

	data_g = data;

	var alpha_scale = d3.scale.linear()
		.domain([0.1, d3.max(data, function(row) { return row.count })])
		.range([0, 1]);

	data.forEach(function(row) {
		if(!(row.distance == 0)) {
			draw_route(row.polyline, alpha_scale(row.count), "#1ac6ff", 2.00, false);
		} });


})