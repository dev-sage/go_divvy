library(ggplot2)
library(ggmap)
library(stats)
library(dplyr)


# Determine Most Common Route Pairs
divvy_matched <- divvy_matched[,c("from_station_id", "to_station_id")]
from_group <- group_by(divvy_matched, from_station_id, to_station_id)
(from_group_summ <- summarise(from_group, count = n()))

# Determine Greatest From -> To combinations. 
# Do not count trips to / from self.
station_combo <- from_group_summ[from_group_summ$from_station_id != from_group_summ$to_station_id, ]
station_combo <- station_combo[order(station_combo$count, decreasing = TRUE), ]


colnames(divvy_matched)
# Get Routing Directions for Top 50
station_combo_1000 <- station_combo[1:1000,]
divvy_matched_only_geo <- divvy_matched[, c("from_station_id", "to_station_id", "from_station_name", "to_station_name",
                                            "from_lng", "to_lng", "from_lat", "to_lat")]
top_1000_combos_full <- left_join(station_combo_1000, divvy_matched_only_geo, by = c("from_station_id" = "from_station_id",
                                                                       "to_station_id"= "to_station_id"))


# Collect only the unique rows.
top_combos_geo <- top_1000_combos_full[!duplicated(top_1000_combos_full), ]
