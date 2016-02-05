library(httr)

###### Utility Functions ######
format_loc <- function(string) {
  new_string <- gsub(" ", "+", string)
  return(new_string)
}

###### Geocode ######
osrm_geocode <- function(location, label) {
  http_pre <- "http://nominatim.openstreetmap.org/?format=json&addressdetails=1&q="
  http_post <- "&format=json&limit=1"
  infix <- format_loc(location)
  http_addy <- paste0(http_pre, infix, http_post)
  response <- GET(http_addy)
  content <- content(response)
  
  if(length(content) > 0) {
    lat <- content[[1]]$lat
    lon <- content[[1]]$lon
  } else {
    lat <- NA
    lon <- NA
  }
 
  df <- data.frame(location, lat, lon, stringsAsFactors = FALSE)
  colnames(df) <- c(label, paste0(label, "_lat"), paste0(label, "_lon"))
  return(df)
}

###### Routing ######
mapquest_route <- function(origin_lat, origin_lon, dest_lat, dest_lon, key1 = NULL, key2 = NULL) {
  http_pre <- sprintf("http://www.mapquestapi.com/directions/v2/route?key=%s&transportMode=BICYCLE&fullShape=true&shapeFormat=cmp&from=%s&to=%s", 
                      Sys.getenv("mapquest_key"), paste(origin_lat, origin_lon, sep = ","), paste(dest_lat, dest_lon, sep = ","))
  response <- GET(http_pre)
  distance <- content(response)$route$distance
  time <- content(response)$route$time
  polyline <- content(response)$route$shape$shapePoints
  if(is.null(polyline)) {
    return(NA)
  } else { 
    route_df <- data.frame(polyline, distance, time, key1, key2, stringsAsFactors = FALSE)
    return(route_df)
  }
}




