library(plumber)

#* @apiTitle scPower API

#* Return the dataset as JSON
#* @param dataset The name of the dataset
#* @get /data
# example usage: http://localhost:8000/data?dataset=iris
function(dataset) {
  data <- get(dataset, "package:datasets")
  as.data.frame(data)
}

# Enable CORS
#* @filter cors
function(res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  plumber::forward()
}
