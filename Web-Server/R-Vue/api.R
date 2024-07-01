library(plumber)

#* @apiTitle Table API

#* Return a summary of the dataset
#* @param dataset The name of the dataset
#* @get /summary
function(dataset) {
  data <- get(dataset, "package:datasets")
  summary(data)
}

#* Return the dataset as JSON
#* @param dataset The name of the dataset
#* @get /data
function(dataset) {
  data <- get(dataset, "package:datasets")
  as.data.frame(data)
}

#* Subtract two numbers
#* @param x The first number
#* @param y The second number
#* @get /subtract/:x/:y
function(x, y) {
  result <- as.numeric(x) - as.numeric(y)
  list(result = result)
}

# Enable CORS
#* @filter cors
function(res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  plumber::forward()
}
