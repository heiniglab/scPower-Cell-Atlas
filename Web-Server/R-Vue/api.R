library(plumber)
library(jsonlite)

data <- readRDS("scPower_shiny/power_study_plot.rds")

#* @apiTitle RDS Data API
#* @get /data
function() {
  return(toJSON(data))
}