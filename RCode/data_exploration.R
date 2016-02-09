library(ggplot2)
library(ggmap)
library(stats)
library(dplyr)
library(lubridate)
library(gridExtra)
library(sqldf)
library(scales)
library(tidyr)
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
                  legend.background = element_rect(fill = "#EDEDED"),
                  panel.grid.major = element_line(color = "#CDCDCD"),
                  panel.grid.major.x = element_blank(),
                  axis.title.x = element_blank(),
                  title = element_text(size = 17, color = "#3D3D3D", face = "bold"),
                  axis.title.y = element_text(size = 16),
                  axis.text = element_text(size = 14),
                  axis.ticks = element_blank(),
                  panel.grid.minor = element_blank(),
                  plot.margin = unit(c(0.5, 0.5, 0.5, 0.5), "cm"),
                  legend.text = element_text(size = 12, face = "bold", color = "#3D3D3D",),
                  legend.key = element_blank())

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

divvy_quarter <- filter(divvy_days_only_summ, month(day) %in% c(1,2,3))
ggplot(data = divvy_quarter, aes(x = day, y = count)) + geom_path(col = "#1ac6ff", lwd = 1) + 
  scale_x_date(date_breaks = "day", date_labels = "%a") +
#   scale_y_continuous(breaks = c(0, 5000, 10000, 15000, 20000, 25000)) + 
#   coord_cartesian(ylim = c(5000, 25000)) + 
  ylab("Daily Ridership\n") + ggtitle(expression(atop(bold("Divvy December Ridership"), atop("(Daily Totals, 2015)")))) + 
  my_theme + theme(axis.text.x = element_text(angle = 0), 
                   axis.ticks.x = element_line(size = 2), 
                   panel.grid.major.x = element_line(color = "#CDCDCD", size = 0.25))


# Getting total average ridership by day.
# Get the unique grouping variable.
divvy_days <- divvy_days_only_summ
divvy_days$day_name <- format(divvy_days_only_summ$day, "%A")
divvy_days <- divvy_days[, c("day_name", "count")]
divvy_days_g <- group_by(divvy_days, day_name)
divvy_summ <- summarise(divvy_days_g, total_count = sum(count))

divvy_final_cold <-filter(divvy_days_only_summ, month(divvy_days_only_summ$day) %in% c(1, 2, 3, 4, 11, 12))
divvy_final_cold$day_name <- format(divvy_final_cold$day, "%A")
divvy_final_cold <- divvy_final_cold[, c("day_name", "count")]
divvy_days_g <- group_by(divvy_final_cold, day_name)
(divvy_summ <- summarise(divvy_days_g, total_count = sum(count)))
cold_divvy <- divvy_summ
cold_divvy$perc <- ifelse(cold_divvy$total_count, cold_divvy$total_count / (sum(cold_divvy$total_count)))

divvy_final_cold <-filter(divvy_days_only_summ, month(divvy_days_only_summ$day) %in% c(5, 6, 7, 8, 9, 10))
divvy_final_cold$day_name <- format(divvy_final_cold$day, "%A")
divvy_final_cold <- divvy_final_cold[, c("day_name", "count")]
divvy_days_g <- group_by(divvy_final_cold, day_name)
(divvy_summ <- summarise(divvy_days_g, total_count = sum(count)))
warm_divvy <- divvy_summ
warm_divvy$perc <- ifelse(warm_divvy$total_count, warm_divvy$total_count / (sum(warm_divvy$total_count)))

#######################################################
# Describe Ridership #
#######################################################
# Get Age Distribution
divvy_final$age <- ( 2015 - divvy_final$birth_year)
subscriber_data <- filter(divvy_final, toupper(user_type) == "SUBSCRIBER" & !is.na(gender) & age < 100)

ggplot(data = subscriber_data, aes(x = age)) + 
  geom_bar(aes(y = (..count..)/sum(..count..)),  fill = "#FFA500") + 
  scale_y_continuous(labels = percent) +  
  scale_x_discrete(breaks = c(16, seq(20, max(subscriber_data$age), by = 5))) + 
  ylab("Subscriber Base\n") + ggtitle("Subscriber Age Distribution") + 
  my_theme

ggplot(data = subscriber_data, aes(x = gender)) + 
  geom_bar(aes(y = (..count..)/sum(..count..)), fill = c("#FFA500", "#1ac6ff")) + 
  scale_y_continuous(labels = percent) + 
  expand_limits(y = c(0, 1)) + 
  ylab("Subscriber Makeup\n") + ggtitle("Subscriber Gender Distribution") + 
  my_theme

ggplot(data = subscriber_data, aes(x = age, fill = gender)) + 
  geom_bar(aes(y = (..count..)/sum(..count..))) + 
  scale_y_continuous(labels = percent) +  
  scale_fill_manual(values = c("#FFA500", "#1ac6ff"), name = "Gender") +
  scale_x_discrete(breaks = c(16, seq(20, max(subscriber_data$age), by = 5))) + 
  ylab("Subscriber Base\n") + ggtitle(expression(atop(bold("Divvy Subscriber Age Distribution"), atop("(2015)")))) + 
  my_theme


divvy_days_gender <- data.frame(day = as.Date(subscriber_data$start_time, "%m/%d/%y", tz = "UTC"), gender = subscriber_data$gender)
divvy_days_gender_g <- group_by(divvy_days_gender, day, gender)
divvy_days_gender_summ <- summarise(divvy_days_gender_g, count = n())

divvy_male <- filter(divvy_days_gender_summ , gender == "Male")
divvy_female <- filter(divvy_days_gender_summ, gender == "Female")
divvy_gender_join <- inner_join(divvy_male, divvy_female, by = c("day" = "day"))
divvy_gender_join$male_perc <- divvy_gender_join$count.x / (divvy_gender_join$count.y + divvy_gender_join$count.x)
divvy_gender_join$female_perc <- divvy_gender_join$count.y / (divvy_gender_join$count.x + divvy_gender_join$count.y)
divvy_male_count <- divvy_gender_join[,c("day", "gender.x", "count.x", "male_perc")]
divvy_female_count <- divvy_gender_join[,c("day", "gender.y", "count.y", "female_perc")]
colnames(divvy_male_count) <- c("day", "gender", "count", "perc")
colnames(divvy_female_count) <- c("day", "gender", "count", "perc")
divvy_gender_counts <- rbind(divvy_male_count, divvy_female_count)

ggplot(data = divvy_gender_counts, aes(x = day, y = perc, col = gender)) + geom_path() + 
  scale_x_date(date_breaks = "month", date_labels = "%B")
  


divvy_gender_counts$day_name <- wday(divvy_gender_counts$day)
divvy_gender_counts_g <- group_by(divvy_gender_counts, gender, day_name)
divvy_gender_counts_summ <- summarise(divvy_gender_counts_g, mean_perc = mean(perc))





fdafs













#### Monthly averages
divvy_days_gender <- data.frame(day = format(subscriber_data$start_time, "%m/%y"), gender = subscriber_data$gender)
divvy_days_gender_g <- group_by(divvy_days_gender, day, gender)
divvy_days_gender_summ <- summarise(divvy_days_gender_g, count = n())



















divvy_male <- filter(divvy_days_gender_summ , gender == "Male")
divvy_female <- filter(divvy_days_gender_summ, gender == "Female")
divvy_gender_join <- inner_join(divvy_male, divvy_female, by = c("day" = "day"))
divvy_gender_join$male_perc <- divvy_gender_join$count.x / (divvy_gender_join$count.y + divvy_gender_join$count.x)
divvy_gender_join$female_perc <- divvy_gender_join$count.y / (divvy_gender_join$count.x + divvy_gender_join$count.y)
divvy_male_count <- divvy_gender_join[,c("day", "gender.x", "count.x", "male_perc")]
divvy_female_count <- divvy_gender_join[,c("day", "gender.y", "count.y", "female_perc")]
colnames(divvy_male_count) <- c("day", "gender", "count", "perc")
colnames(divvy_female_count) <- c("day", "gender", "count", "perc")
divvy_gender_counts <- rbind(divvy_male_count, divvy_female_count)

divvy_gender_counts$month <- as.Date(as.character(divvy_gender_counts$day), "%m/%y")
ggplot(data = divvy_gender_counts, aes(x = day, y = count, col = gender)) + geom_path()
