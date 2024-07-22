library(jsonlite)
library(plumber)

#* @apiTitle RDS Data API
#* @get /scatter_data
function() {
  # Read the JSON file
  data <- fromJSON("scPower_shiny/power_study_plot.json")
  
  # Return the data as JSON
  return(data)
}

#* @apiTitle RDS Data API
#* @get /influence_data
function() {
  # Read the JSON file
  data <- fromJSON("scPower_shiny/power_study.json")
  
  # Return the data as JSON
  return(data)
}