# Necessary Libraries
library(readr)


# From https://www.divvybikes.com/data
# THE DATA
# Each trip is anonymized and includes:
#   
# Trip start day and time
# Trip end day and time
# Trip start station
# Trip end station
# Rider type (Member or 24-Hour Pass User)
# If a Member trip, it will also include Member’s gender and year of birth

# Read in the Data
divvy_initial <- read_csv("~/Desktop/divvy_trips/Divvy_Trips_2015_07.csv",
                          col_types = cols(trip_id = col_integer(),
                                      starttime = col_date(format = "%m/%d/%Y %H:%M"),
                                      stoptime =  col_date(format = "%m/%d/%Y %H:%M"),
                                      bikeid = col_integer(),
                                      tripduration = col_integer(),
                                      from_station_id = col_integer(),
                                      from_station_name = col_character(),
                                      to_station_id = col_integer(),
                                      to_station_name = col_character(),
                                      usertype = col_character(),
                                      gender = col_character(),
                                      birthyear = col_integer()))

# I don't like these column names
colnames(divvy_initial) <- c("start_time", "stop_time", "bike_id", "trip_duration", "from_station_id", 
                             "from_station_name", "to_station_id", "to_station_name", "user_type", "gender", "birth_year")

