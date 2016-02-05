var $trip_message;
function trip_info(trip) {
	$trip_message = $("<div id = 'message'></div>");
	$("body").append($trip_message);
	$trip_message.append("<center> From: " + trip.from_station_name + "<br> To: " + trip.to_station_name +
		"<br> Distance: " + trip.distance + "km" + "<br> Time: " + trip.time / 60 + "mins </center>");
}

function remove_trip() {
	$trip_message.remove();
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

	// This prints the Trip TO and FROM points, with distances and times.
	/*var $message;
	function pull_author(time1) {
		$message = $("<div id = 'message'></div>");
		$("body").append($message);
		$message.append("<center> @" + time1[0].value + "</center>");
	}

	function remove_author() {
		$message.remove();
	} */ 


	var padding = 50, w = window.innerWidth * 0.60, h = window.innerHeight * 0.70;

	var xScale = d3.scale.linear()
							.domain([0, d3.max(data, function(row) { return row.distance; })])
							.range([padding, w - padding]);

	var yScale = d3.scale.linear()
							.domain([0, d3.max(data, function(row) { return row.time; })])
							.range([h - padding, padding]);

	var r_scale = d3.scale.sqrt()
							.domain([0, d3.max(data, function(row) { return row.count; })])
							.range([0, 10]);

	var xAxis = d3.svg.axis()
						.scale(xScale)
						.orient("bottom");

	var yAxis = d3.svg.axis()
						.scale(yScale)
						.orient("left");

	var svg = d3.select("#scatter_layout")
				.append("svg")
				.attr("width", w)
				.attr("height", h);

	// Points
	svg.selectAll("circle")
		.data(data)
		.enter()
		.append("circle")
		.attr("cx", function(row) { return xScale(row.distance); })
		.attr("cy", function(row) { return yScale(row.time); })
		.attr("r", function(row) { return r_scale(row.count); })
		.attr("stroke", "#1ac6ff")
		.on("mouseover", function(row) { trip_info(row); })
		.on("mouseout", function(row) { remove_trip(); });
		

	// xAxis
	svg.append("g")
		.attr("class", "axis")
		.attr("transform", "translate(0," + (h - padding) + ")")
		.call(xAxis);

	// yAxis
	svg.append("g")
		.attr("class", "axis")
		.attr("transform", "translate(" + padding + ",0)")
		.call(yAxis);

});
