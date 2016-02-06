var $trip_message;
function trip_info(trip) {
	$trip_message = $("<div id = 'message'></div>");
	$("body").append($trip_message);
	$trip_message.append("<center> From: " + trip.from_station_name + "<br> To: " + trip.to_station_name +
		"<br> Distance: " + trip.distance + " km" + "<br> Frequency: " + trip.count + " trips </center>");	
}

function remove_trip_info() {
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

	var padding = 100, w = window.innerWidth * 0.60, h = window.innerHeight * 1;

	var xScale = d3.scale.linear()
							.domain([0, d3.max(data, function(row) { return row.distance; })])
							.range([padding, w - padding]);

	var yScale = d3.scale.linear()
							.domain([0, d3.max(data, function(row) { return row.count; })])
							.range([h - padding, padding]);

	var r_scale = d3.scale.sqrt()
							.domain([0, d3.max(data, function(row) { return row.count; })])
							.range([0, 15]);

	var opacity_scale = d3.scale.sqrt()
								.domain([0	, d3.max(data, function(row) { return row.count; })])
								.range([0, 1]);

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
		.attr("cy", function(row) { return yScale(row.count); })
		.attr("r", function(row) { return r_scale(row.count); })
		.attr("opacity", function(row) { return opacity_scale(row.count); })
		.attr("stroke", "#1ac6ff")
		.on("mouseover", function(row) { 
			d3.select(this)
				.transition()
				.duration(100)
				.attr("fill", "orange")
				.attr("opacity", 1);
			trip_info(row);
			draw_route(row.polyline, 0.85, "orange", 4.0, true); 
		})
		.on("mouseout", function(row) { 
			d3.select(this)
				.transition()
				.duration(275)
				.attr("fill", "black")
				.attr("opacity", function(row) { return opacity_scale(row.count); });
				
				remove_trip_info(); 

				remove_trip_path();
		});
		
	// xAxis
	svg.append("g")
		.attr("class", "axis")
		.attr("transform", "translate(0," + (h - padding) + ")")
		.call(xAxis);

	svg.append("text")
		.attr("text-anchor", "middle")
		.attr("x", w / 2 )
		.attr("y", h - 40)
		.text("Distance");

	svg.append("text")
		.attr("text-anchor", "middle")
		.attr("x", w / 2)
		.attr("y", 50)
		.attr("font-size", 32)
		.text("1000 Most Popular Divvy Trips (2015)");

	// yAxis
	svg.append("g")
		.attr("class", "axis")
		.attr("transform", "translate(" + padding + ",0)")
		.call(yAxis);

	svg.append("text")
		.attr("text-anchor", "bottom")
		.attr("y", 0 - 10)
		.attr("x", 0 - (h * 0.60))
		.attr("dy", "1.5em")
		.attr("transform", "rotate(-90)")
		.text("Count of Trips Taken");
});
