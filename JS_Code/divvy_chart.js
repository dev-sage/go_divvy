var width = 600, height = 1000;

var svg = d3.select("#force_layout").append("svg")
			.attr("width", width)
			.attr("height", height);

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

	var edgeScale = d3.scale.linear()
							.domain([0, 6])
							.range([0, 20]);


	var force = d3.layout.force()
				.size([width, height])
				.charge([-25])
				.linkDistance(function(d) { return edgeScale(d.distance)});
				

	var nodesByName = {};

	data.forEach(function(data) {
		data.source = nodeByName(data.from_station_addy);
		data.target = nodeByName(data.to_station_addy);
	});


	var nodes = d3.values(nodesByName);

	console.log(nodes);
	var link = svg.selectAll(".link")
					.data(data)
					.enter()
					.append("line")
					.attr("class", "link");
					


	var node = svg.selectAll(".node")
					.data(nodes)
					.enter()
					.append("circle")
					.attr("class", "node")
					.attr("r", 4.5)
					.on("click", function(d) { console.log(d.name); })
					.call(force.drag);

	console.log("made it here!");


	force
		 .nodes(nodes)
		 .links(data)
		 .on("tick", tick)
		 .start();

	function tick() {
		link.attr("x1", function(d) { return d.source.x; })
			.attr("y1", function(d) { return d.source.y; })
			.attr("x2", function(d) { return d.target.x; })
			.attr("y2", function(d) { return d.target.y; });

		node.attr("cx", function(d) { return d.x; })
			.attr("cy", function(d) { return d.y; });
	}


	function nodeByName(name) {
		 return nodesByName[name] || (nodesByName[name]  = {name: name});
	}
});