library(ggplot2)
library(ggmap)
library(stats)
library(dplyr)

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


































map <- get_map("chicago", source = "google", zoom = 12, color = "bw", maptype = "blank")
# 
# my_paths <- data.frame()
# for(i in 1:nrow(combos_with_lines)) {
#   path <- decodeLine(combos_with_lines$polyline[i])
#   path$group <- paste0(combos_with_lines$from_station_id[i],
#                        combos_with_lines$to_station_id[i])
#   path$alpha <- alpha_scale(combos_with_lines$count[i])
#   my_paths <- rbind(my_paths, path)
# }
# 
# (max(my_paths$alpha) - min(my_paths$alpha)) / 100
# 
# scale_factor <-  1 / 6182 
# 
# alpha_scale <- function(num) {
#   return((num) / 6182)
# }
# 

max(my_paths$lon)

paths_clean <- my_paths[my_paths$lon != 18.68812, ]

ggplot(data = paths_clean, aes(x = lon, y = lat, group = group, alpha = alpha * 0.50)) + 
  geom_path(lwd = 0.25, col = "#1ac6ff") + coord_map(projection = "mercator") +
  guides(alpha = FALSE) + 
  theme_void()


theme_void <- function(base_size = 12, base_family = "") {
  theme(
    # Use only inherited elements and make everything blank
    line =               element_blank(),
    text =               element_blank(),
    plot.margin =        unit(c(0, 0, 0, 0), "lines"),
    panel.background =   element_rect(fill = "black"),
    plot.background =    element_rect(fill = "black"),
    
    complete = TRUE
  )
}