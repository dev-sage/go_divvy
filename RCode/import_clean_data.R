# Necessary Libraries
library(readr)
library(dplyr)

my_working_dir <- "~/Google Drive/Go Divvy/"
# From https://www.divvybikes.com/data: 
#"Trip start day and time
# Trip end day and time
# Trip start station
# Trip end station
# Rider type (Member or 24-Hour Pass User)
# If a Member trip, it will also include Member’s gender and year of birth"

# Reading in data, but we've got a few files, so using a function to do so, with columns types explicitly defined.
read_divvy <- function(file_name) {
  data <- read_csv(file_name,
          col_types = cols(trip_id = col_integer(),
                          starttime = col_datetime(format = "%m/%d/%Y %H:%M"),
                          stoptime =  col_datetime(format = "%m/%d/%Y %H:%M"),
                          bikeid = col_integer(),
                          tripduration = col_integer(),
                          from_station_id = col_integer(),
                          from_station_name = col_character(),
                          to_station_id = col_integer(),
                          to_station_name = col_character(),
                          usertype = col_character(),
                          gender = col_character(),
                          birthyear = col_integer()))
  return(data)
}

############################### READ DATA ###############################
# Trip Data:
divvy_q1 <- read_divvy("~/Desktop/divvy_trips/Divvy_Trips_2015-Q1.csv")
divvy_q2 <- read_divvy("~/Desktop/divvy_trips/Divvy_Trips_2015-Q2.csv")
divvy_q3_07 <- read_divvy("~/Desktop/divvy_trips/Divvy_Trips_2015_07.csv")
divvy_q3_08 <- read_divvy("~/Desktop/divvy_trips/Divvy_Trips_2015_08.csv")
divvy_q3_09 <- read_divvy("~/Desktop/divvy_trips/Divvy_Trips_2015_09.csv")
divvy_q4 <- read_divvy("~/Desktop/divvy_trips/Divvy_Trips_2015_Q4.csv")

# Station Data
divvy_stations <- read_csv("~/Desktop/divvy_trips/divvy_stations_2015.csv")
########################### END READ DATA ###############################


############################### JOIN DATA ###############################
# Concatenate tables
divvy_data <- rbind(divvy_q1, divvy_q2, divvy_q3_07, divvy_q3_08, divvy_q3_09, divvy_q4)

# Change columns names to be more readable.
colnames(divvy_data) <- c("trip_id", "start_time", "stop_time", "bike_id", "trip_duration", "from_station_id", 
                          "from_station_name", "to_station_id", "to_station_name", "user_type", "gender", "birth_year")
# Left Join ( Trip <- Station )
# Note: This probably isn't the best way to do so, will revise.

# Renaming stations to avoid confusion on merge.
colnames(divvy_stations) <- c("id", "name", "from_lat", "from_lng", "from_dpcap", "from_land")
divvy_matched <- left_join(divvy_data, divvy_stations, by = c(c("from_station_id" = "id", "from_station_name" = "name")))
# Once again renaming stations to avoid confusion on merge.
colnames(divvy_stations) <- c("id", "name", "to_lat", "to_lng", "to_dpcap", "to_land")
divvy_matched <- left_join(divvy_matched, divvy_stations, by = c(c("to_station_id" = "id", "to_station_name" = "name")))
divvy_final <- divvy_matched # This is the final object we'll play with.
########################### END JOIN DATA ###############################


############################### SAVE DATA ###############################
# Save to non-git folder. 
write.csv(divvy_final, file = "~/Google Drive/Go Divvy/divvy_data.csv", row.names = FALSE)
# Save RObject
saveRDS(divvy_final, file = "~/Google Drive/Go Divvy/divvy_data.rda")

# Create compressed data for github upload.
system("cp '/Users/sagelane/Google Drive/Go Divvy/divvy_data.csv' '/Users/sagelane/Google Drive/Go Divvy/go_divvy/data/divvy_data_small.csv'")
system("gzip '/Users/sagelane/Google Drive/Go Divvy/go_divvy/data/divvy_data_small.csv'")
########################### END SAVE DATA ###############################
divvy_final <- readRDS(file = "~/Google Drive/Go Divvy/divvy_data.rda")




