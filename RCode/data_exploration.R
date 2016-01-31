library(ggplot2)
library(ggmap)
library(stats)
library(dplyr)
library(lubridate)

# Determine Most Common Route Pairs
divvy_final <- divvy_final[,c("from_station_id", "to_station_id")]
from_group <- group_by(divvy_final, from_station_id, to_station_id)
(from_group_summ <- summarise(from_group, count = n()))

# Determine Greatest From -> To combinations. 
# Do not count trips to / from self.
station_combo <- from_group_summ[from_group_summ$from_station_id != from_group_summ$to_station_id, ]
station_combo <- station_combo[order(station_combo$count, decreasing = TRUE), ]


colnames(divvy_final)
# Get Routing Directions for Top 1000
station_combo_1000 <- station_combo[1:1000,]
divvy_final_only_geo <- divvy_final[, c("from_station_id", "to_station_id", "from_station_name", "to_station_name",
                                            "from_lng", "to_lng", "from_lat", "to_lat")]
top_1000_combos_full <- left_join(station_combo_1000, divvy_final_only_geo, by = c("from_station_id" = "from_station_id",
                                                                       "to_station_id"= "to_station_id"))


# Collect only the unique rows.
top_combos_geo <- top_1000_combos_full[!duplicated(top_1000_combos_full), ]

# Use OSRM package to pull polylines for data (Not the most efficient way of building the data, will re-do)
# polyline_data <- data.frame()
# for(i in 1:nrow(top_combos_geo)) {
#   line_data <- mapquest_route(top_combos_geo$from_lat[i], top_combos_geo$from_lng[i],
#                                      top_combos_geo$to_lat[i], top_combos_geo$to_lng[i],
#                                      top_combos_geo$from_station_id[i], top_combos_geo$to_station_id[i])
#   polyline_data <- rbind(polyline_data, line_data)
# }

str(polyline_data)
str(top_combos_geo)
# Recombine Data and Polylines
combos_with_lines <- inner_join(top_combos_geo, polyline_data, by = c("from_station_id" = "key1",
                                                                      "to_station_id" = "key2"))

write.table(combos_with_lines, 
            file = "/Users/sagelane/Google Drive/Go Divvy/go_divvy/data/combo_line.csv",
            row.names = FALSE, sep = ",", col.names = FALSE, append = TRUE)

#######################################################
# Get numbers of trips by the hour in 24 hour periods #
#######################################################
# divvy_final <- read_csv(file = "~/Google Drive/Go Divvy/divvy_data.csv")
head(divvy_final$start_time)[1]
divvy_final$start_time[1]

