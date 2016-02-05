library(ggplot2)
library(ggmap)
library(stats)
library(dplyr)
library(lubridate)

# Determine Most Common Station Pairs. The object here is to determine
# which trips are the most common. A trip is defined by one origin -> destination leg.
divvy_to_from <- divvy_final[,c("from_station_id", "to_station_id")]
from_group <- group_by(divvy_to_from, from_station_id, to_station_id)
from_group_summ <- summarise(from_group, count = n())

# Determine Greatest From -> To combinations. 
# For this analysis, we'll consider the special case where the trip has a common origin / destination,
# i.e. returning the bike to the same station from which it was taken. This will have to be taken into 
# account later, when polylines are being drawn.
# station_combo <- from_group_summ[from_group_summ$from_station_id != from_group_summ$to_station_id, ]
station_combo <- from_group_summ[order(from_group_summ$count, decreasing = TRUE), ]

# Determine Top 1000 Trips. Here, we're subsetting the divvy dataset to only geographic features so that 
# we can determine unique trip combination, regardless of specific trips taken within this combination. 
# Recombination will take place later to create a complete dataset.
top_1000_trips <- station_combo[1:1000,]
divvy_geo_only <- divvy_final[, c("from_station_id", "to_station_id", "from_station_name", "to_station_name",
                                        "from_lng", "to_lng", "from_lat", "to_lat")]
top_1000_complete <- left_join(top_1000_trips, divvy_geo_only, by = c("from_station_id" = "from_station_id",
                                                                       "to_station_id"= "to_station_id"))

# Collect only the unique rows.
top_combos_unique <- top_1000_complete[!duplicated(top_1000_complete), ]

# Use OSRM code to pull polylines for data (Not the most efficient way of building the data, will re-do)
# polyline_data <- data.frame()
# for(i in 1:nrow(top_combos_unique)) {
#   line_data <- mapquest_route(top_combos_unique$from_lat[i], top_combos_unique$from_lng[i],
#                               top_combos_unique$to_lat[i], top_combos_unique$to_lng[i],
#                               top_combos_unique$from_station_id[i], top_combos_unique$to_station_id[i])
#   polyline_data <- rbind(polyline_data, line_data)
# }

# Recombine Data and Polylines
combos_with_lines <- inner_join(top_combos_unique, polyline_data, by = c("from_station_id" = "key1", 
                                                                         "to_station_id" = "key2"))

# Create unique from_to id
combos_with_lines$id <- paste0(combos_with_lines$from_station_id, combos_with_lines$to_station_id)

test_combo <- combos_with_lines[combos_with_lines$from_station_id != combos_with_lines$to_station_id, ]

write.table(combos_with_lines, 
            file = "/Users/sagelane/Google Drive/Go Divvy/go_divvy/data/combo_lines.csv",
            row.names = FALSE, sep = ",", col.names = TRUE, append = FALSE)

#######################################################
# Get numbers of trips by the hour in 24 hour periods #
#######################################################
ggplot(data = combos_with_lines, aes(x = distance, y = count, color = factor(floor(distance)))) + geom_point()

