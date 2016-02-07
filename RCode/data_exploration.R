library(ggplot2)
library(ggmap)
library(stats)
library(dplyr)
library(lubridate)
library(gridExtra)

#######################################################
# FOR MAP + SCATTERPLOT #
#######################################################

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
# TEMPORALITY #
#######################################################

# Set theme for use.
my_theme <- theme(plot.background = element_rect(fill = "#EDEDED"),
                  panel.background = element_rect(fill = "#EDEDED"),
                  panel.grid.major = element_line(color = "#CDCDCD"),
                  panel.grid.major.x = element_blank(),
                  axis.title.x = element_blank(),
                  title = element_text(size = 17, color = "#3D3D3D", face = "bold"),
                  axis.title.y = element_text(size = 16),
                  axis.text = element_text(size = 14),
                  axis.ticks = element_blank(),
                  panel.grid.minor = element_blank(),
                  plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"))

# Overall Hourly Rate
hours_only <- as.data.frame(hour(divvy_final$start_time))
colnames(hours_only) <- "hours"
hours_g <- group_by(hours_only, hours)
hours_summ <- summarise(hours_g, count = n())
hours_summ$hourly_rate <- hours_summ$count / length(unique(yday(divvy_final$start_time)))
hours_summ <- rbind(hours_summ, c(-1, 0, 0)) # Purely aesthetic, to balance the empty left / right of graph.
overall_hourly_plot <- ggplot(data = hours_summ, aes(x = hours, y = hourly_rate)) + geom_bar(stat = "identity", fill = "#1ac6ff") +
  ylab("Riders Per Hour\n") + ggtitle(expression(atop(bold("Divvy Ridership Daily Average"), atop("(2015)")))) + 
  scale_x_discrete(breaks = c(-1, 0, 3, 6, 9, 12, 15, 18, 21, 24), 
                   labels = c("-1"= "", "0" = "12am", "3" = "3am", "6" = "6am", "9" = "9am", 
                              "12" = "12pm", "15" = "3pm", "18" = "6pm", "21" = "9pm", "24" = "12am")) + 
  coord_cartesian(ylim = c(0, 1000)) + scale_y_continuous(breaks = c(0, 250, 500, 750, 1000)) + my_theme
  

# Weekday Hourly Rate
# Lubridate wday()s are 1-7, Sun - Sat
divvy_weekdays <- divvy_final[!wday(divvy_final$start_time) %in% c(1,7), ] 
weekday_hours_only <- as.data.frame(hour(divvy_weekdays$start_time))
colnames(weekday_hours_only) <- "weekday_hours"
weekday_hours_g <- group_by(weekday_hours_only, weekday_hours)
weekday_hours_summ <- summarise(weekday_hours_g, count = n())
weekday_hours_summ <- rbind(weekday_hours_summ, c(-1, 0, 0)) # Purely aesthetic, to balance the empty left / right of graph.
weekday_hours_summ$hourly_rate <- weekday_hours_summ$count / length(unique(yday(divvy_weekdays$start_time)))
weekday_hourly_plot <- ggplot(data = weekday_hours_summ, aes(x = weekday_hours, y = hourly_rate)) + geom_bar(stat = "identity", fill = "#1ac6ff") +
  ylab("Riders Per Hour\n") + ggtitle("Daily Ridership Average (2015)\n\nMonday - Friday") + 
  scale_x_discrete(breaks = c(-1, 0, 3, 6, 9, 12, 15, 18, 21, 24), 
                   labels = c("-1"= "", "0" = "12am", "3" = "3am", "6" = "6am", "9" = "9am", 
                              "12" = "12pm", "15" = "3pm", "18" = "6pm", "21" = "9pm", "24" = "12am")) + 
  coord_cartesian(ylim = c(0, 1000)) + scale_y_continuous(breaks = c(0, 250, 500, 750, 1000)) + 
  my_theme

# Weekend Hourly Rate
# Lubridate wday()s are 1-7, Sun - Sat
divvy_weekend <- divvy_final[wday(divvy_final$start_time) %in% c(1,7), ]
weekend_hours_only <- as.data.frame(hour(divvy_weekend$start_time))
colnames(weekend_hours_only) <- "weekend_hours"
weekend_hours_g <- group_by(weekend_hours_only, weekend_hours)
weekend_hours_summ <- summarise(weekend_hours_g, count = n())
weekend_hours_summ <- rbind(weekend_hours_summ, c(-1, 0, 0)) # Purely aesthetic, to balance the empty left / right of graph.
weekend_hours_summ$hourly_rate <- weekend_hours_summ$count / length(unique(yday(divvy_weekend$start_time)))
weekend_hourly_plot <- ggplot(data = weekend_hours_summ, aes(x = weekend_hours, y = hourly_rate)) + geom_bar(stat = "identity", fill = "#1ac6ff") +
  ggtitle("Saturday - Sunday") + ylab("Riders Per Hour\n")+ 
  scale_x_discrete(breaks = c(-1, 0, 3, 6, 9, 12, 15, 18, 21, 24), 
                   labels = c("-1"= "", "0" = "12am", "3" = "3am", "6" = "6am", "9" = "9am", 
                              "12" = "12pm", "15" = "3pm", "18" = "6pm", "21" = "9pm", "24" = "12am")) + 
  coord_cartesian(ylim = c(0, 1000)) + scale_y_continuous(breaks = c(0, 250, 500, 750, 1000, 1250)) + 
  my_theme

grid.arrange(weekday_hourly_plot, weekend_hourly_plot, ncol = 1)


# Daily Ridership Throughout Year
divvy_days_only <- as.data.frame(as.Date(divvy_final$start_time, "%m/%d/%y", tz = "UTC"))
colnames(divvy_days_only) <- "day"
divvy_days_only_g <- group_by(divvy_days_only, day)
divvy_days_only_summ <- summarise(divvy_days_only_g, count = n())
ggplot(data = divvy_days_only_summ, aes(x = day, y = count)) + geom_path(col = "#1ac6ff", lwd = 1) + 
  scale_x_date(date_breaks = "month", date_labels = "%B") +
  scale_y_continuous(breaks = seq(0, 25000, by = 5000)) + my_theme + 
  ylab("Daily Ridership\n") + ggtitle(expression(atop(bold("Divvy Daily Ridership"), atop("(2015)"))))

divvy_june <- filter(divvy_days_only_summ, month(day) == 6)
ggplot(data = divvy_june, aes(x = day, y = count)) + geom_path(col = "#1ac6ff", lwd = 1) + 
  scale_x_date(date_breaks = "day", date_labels = "%a") +
  scale_y_continuous(breaks = c(0, 5000, 10000, 15000, 20000, 25000)) + 
  coord_cartesian(ylim = c(5000, 25000)) + 
  ylab("Daily Ridership\n") + ggtitle(expression(atop(bold("Divvy June Ridership"), atop("(Daily Totals, 2015)")))) + 
  my_theme + theme(axis.text.x = element_text(angle = 0), 
                   axis.ticks.x = element_line(size = 2), 
                   panel.grid.major.x = element_line(color = "#CDCDCD", size = 0.25))