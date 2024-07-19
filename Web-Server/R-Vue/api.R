library(jsonlite)
library(plumber)

#* @apiTitle RDS Data API
#* @get /data
function() {
  # Read the JSON file
  data <- fromJSON("scPower_shiny/power_study_plot.json")
  
  # Return the data as JSON
  return(data)
}