## for getting object size of each dataset

for(datasetID in datasetCollectionCombinedID){
  # datasetID: {[assayID], [tissueID], [cellTypeID]}
  completeDatasetID <- datasetID
  datasetID <- strsplit(datasetID, split = "_")[[1]]
  
  indexOnCollection <- which(sapply(datasetCollectionCombinedID, function(x) x == completeDatasetID))
  print(paste0("index: ", indexOnCollection, "/", length(datasetCollectionCombinedID)))
  
  # ontology ids converted to their ontology names and concatenated
  idToName <- paste(convertIDtoName(datasetID), collapse="_")
  
  
  # covering the code block with try catch in the purpose of
  # catching error for a particular cell type combination inside any dataset
  result <- tryCatch({
    
    dataset <- subset(wholeDataset, assay_ontology_term_id == datasetID[[1]] &
                                    tissue_ontology_term_id == datasetID[[2]] &
                                    cell_type_ontology_term_id == datasetID[[3]])
    
    # cell count threshold
    # if under 50, skip to the next sample
    cellCount <- dataset@assays$RNA@counts@Dim[[2]]
    print(paste0("cellcount: ", cellCount, " - size (GBs): ", object.size(dataset) / 1024^3))
    if(cellCount < 50) {
      next
    }      
  }, 
  
  # error handling part (currently only used for outputting related informations)
  error = function(e) {
    datasetBodySpecific <- paste(numberOfAssays, numberOfTissues, numberOfCellTypes, sep = "_")
    
    errorDF <- data.frame(completeDatasetID,
                          idToName,
                          paste(e),
                          datasetBodySpecific,
                          cellCount)
    # errorDF <- merge(errorDF, expressedGenesDF, by = "cellCount")
    # gammaFits, gammaLinearFits, dispFunEstimation, power
                          
    colnames(errorDF)[3] <- "errorMessage"
    outputResults(errorDF, "error")
  })
  
   # skip current iteration of the loop if an error occurs
  if (inherits(result, "try-error")) {
    next
  }
}

## HEART
# [1] "index: 1/60"
# 0.9 GBs
# [1] "index: 2/60"
# 0.7 GBs
# [1] "index: 3/60"
# 1.2 GBs
# [1] "index: 4/60"  ------------------------------------
# 3.4 GBs
# [1] "index: 5/60"
# 0.5 GBs
# [1] "index: 6/60"
# 0.1 GBs
# [1] "index: 7/60"
# 0.1 GBs
# [1] "index: 8/60"
# 0.5 GBs
# [1] "index: 9/60"
# 0 GBs
# [1] "index: 10/60"
# 0.1 GBs
# [1] "index: 11/60"
# 0.9 GBs
# [1] "index: 12/60" --------------------------------------
# 3.7 GBs
# [1] "index: 13/60"
# 0.7 GBs
# [1] "index: 14/60"
# 0.1 GBs
# [1] "index: 15/60"
# 1.3 GBs
# [1] "index: 16/60"
# 0.1 GBs
# [1] "index: 17/60"
# 0 GBs
# [1] "index: 18/60"
# 0.5 GBs
# [1] "index: 19/60"
# 0.4 GBs

## LUNG
# [1] "index: 1/360" ------------------------------------
# 2 GBs
# [1] "index: 2/360"
# 0.3 GBs
# [1] "index: 3/360"
# 1.5 GBs
# [1] "index: 4/360"
# 0.3 GBs
# [1] "index: 5/360" ----------------------------------
# 2.5 GBs
# [1] "index: 6/360"
# 2.6 GBs
# [1] "index: 7/360"
# 0.1 GBs
# [1] "index: 8/360"
# 0.2 GBs
# [1] "index: 9/360"
# 0.1 GBs
# [1] "index: 10/360"
# 0.2 GBs
# [1] "index: 11/360"
# 0 GBs
# [1] "index: 12/360"
# 0.2 GBs
# [1] "index: 13/360"
# 0.7 GBs
# [1] "index: 14/360"
# 1.5 GBs
# [1] "index: 15/360"
# 0.2 GBs
# [1] "index: 16/360"
# [1] "index: 17/360"
# 0.5 GBs
# [1] "index: 18/360"
# 0.1 GBs
# [1] "index: 19/360"
# 0 GBs
# [1] "index: 20/360"
# 0 GBs
# [1] "index: 21/360"
# 0.7 GBs
# [1] "index: 22/360"
# 0.4 GBs
# [1] "index: 23/360"
# 0.1 GBs
# [1] "index: 24/360"
# 0.8 GBs
# [1] "index: 25/360"
# 0 GBs
# [1] "index: 26/360"
# 0.2 GBs
# [1] "index: 27/360"
# 0.3 GBs
# [1] "index: 28/360"
# 0.5 GBs
# [1] "index: 29/360"
# 0.2 GBs
# [1] "index: 30/360"
# 1 GBs
# [1] "index: 31/360"
# 0.2 GBs
# [1] "index: 32/360"
# 0 GBs
# [1] "index: 33/360"
# 0 GBs
# [1] "index: 34/360"
# 0.2 GBs
# [1] "index: 35/360"
# 0.4 GBs
# [1] "index: 36/360"
# 0.1 GBs
# [1] "index: 37/360"
# 0.2 GBs
# [1] "index: 38/360"
# 0.7 GBs
# [1] "index: 39/360"
# 0.2 GBs
# [1] "index: 40/360"
# 0 GBs
# [1] "index: 41/360"
# 0.1 GBs
# [1] "index: 42/360"
# 0.1 GBs
# [1] "index: 43/360"
# 0 GBs
# [1] "index: 44/360"
# 0.1 GBs
# [1] "index: 45/360"
# 0.1 GBs
# [1] "index: 46/360"
# 0.1 GBs
# [1] "index: 47/360"
# 0.5 GBs
# [1] "index: 48/360"
# 0.1 GBs
# [1] "index: 49/360"
# 0.1 GBs
# [1] "index: 50/360"
# 0.1 GBs
# [1] "index: 51/360"
# 0 GBs
# [1] "index: 52/360"
# 0.1 GBs
# [1] "index: 53/360"
# 0 GBs
# [1] "index: 54/360"
# 0 GBs
# [1] "index: 55/360"
# 0.4 GBs
# [1] "index: 56/360"
# 0.1 GBs
# [1] "index: 57/360"
# 0.3 GBs
# [1] "index: 58/360"
# 0 GBs
# [1] "index: 59/360"
# 0.3 GBs
# [1] "index: 60/360"
# 0.1 GBs
# [1] "index: 61/360"
# 0.2 GBs
# [1] "index: 62/360"
# 0 GBs
# [1] "index: 63/360"
# 0.1 GBs
# [1] "index: 64/360"
# 0.1 GBs
# [1] "index: 65/360"
# 0.1 GBs
# [1] "index: 66/360"
# 0.1 GBs
# [1] "index: 67/360"
# 0.3 GBs
# [1] "index: 68/360"
# 0.1 GBs
# [1] "index: 69/360"
# 0 GBs
# [1] "index: 70/360"
# 0 GBs
# [1] "index: 71/360"
# 0.1 GBs
# [1] "index: 72/360"
# 0.2 GBs
# [1] "index: 73/360"
# 0.1 GBs
# [1] "index: 74/360"
# 0 GBs
# [1] "index: 75/360"
# 0.1 GBs
# [1] "index: 76/360"
# 0 GBs
# [1] "index: 77/360"
# 0.1 GBs
# [1] "index: 78/360"
# 0 GBs
# [1] "index: 79/360"
# 0 GBs
# [1] "index: 80/360"
# 0 GBs
# [1] "index: 81/360"
# 0.1 GBs
# [1] "index: 82/360"
# 0 GBs
# [1] "index: 83/360"
# 0 GBs
# [1] "index: 84/360"
# 0.1 GBs
# [1] "index: 85/360"
# 0.1 GBs
# [1] "index: 86/360"
# 0.1 GBs
# [1] "index: 87/360"
# 0.1 GBs
# [1] "index: 88/360"
# 0.1 GBs
# [1] "index: 89/360"
# 0.1 GBs
# [1] "index: 90/360"
# 0 GBs
# [1] "index: 91/360"
# 0 GBs
# [1] "index: 92/360"
# 0 GBs
# [1] "index: 93/360"
# 0 GBs
# [1] "index: 94/360"
# 0 GBs
# [1] "index: 95/360"
# 0.1 GBs
# [1] "index: 96/360"
# 0 GBs
# [1] "index: 97/360"
# 0 GBs
# [1] "index: 98/360"
# 0.1 GBs
# [1] "index: 99/360"
# 0 GBs
# [1] "index: 100/360"
# 0.1 GBs
# [1] "index: 101/360"
# 0 GBs
# [1] "index: 102/360"
# 0 GBs
# [1] "index: 103/360"
# 0.2 GBs
# [1] "index: 104/360"
# 0 GBs
# [1] "index: 105/360"
# 0.1 GBs
# [1] "index: 106/360"
# 0.2 GBs
# [1] "index: 107/360"
# 0 GBs
# [1] "index: 108/360"
# 0 GBs
# [1] "index: 109/360"
# 0.1 GBs
# [1] "index: 110/360"
# 0.1 GBs
# [1] "index: 111/360"
# 0 GBs
# [1] "index: 112/360"
# 0 GBs
# [1] "index: 113/360"
# 0 GBs
# [1] "index: 114/360"
# 0 GBs
# [1] "index: 115/360"
# 0 GBs
# [1] "index: 116/360"
# [1] "index: 117/360"
# 0 GBs
# [1] "index: 118/360"
# 0.1 GBs
# [1] "index: 119/360"
# 0 GBs
# [1] "index: 120/360"
# 0.1 GBs
# [1] "index: 121/360"
# 0 GBs
# [1] "index: 122/360"
# 0.1 GBs
# [1] "index: 123/360"
# 0 GBs
# [1] "index: 124/360"
# 0.1 GBs
# [1] "index: 125/360"
# 0 GBs
# [1] "index: 126/360"
# 0 GBs
# [1] "index: 127/360"
# 0.1 GBs
# [1] "index: 128/360"
# 0 GBs
# [1] "index: 129/360"
# 0 GBs
# [1] "index: 130/360"
# 0.1 GBs
# [1] "index: 131/360"
# 0 GBs
# [1] "index: 132/360"
# 0 GBs
# [1] "index: 133/360"
# 0 GBs
# [1] "index: 134/360"
# 0 GBs
# [1] "index: 135/360"
# [1] "index: 136/360"
# 0 GBs
# [1] "index: 137/360"
# 0 GBs
# [1] "index: 138/360"
# 0 GBs
# [1] "index: 139/360"
# 0 GBs
# [1] "index: 140/360"
# 0 GBs
# [1] "index: 141/360"
# 0 GBs
# [1] "index: 142/360"
# 0 GBs
# [1] "index: 143/360"
# [1] "index: 144/360"
# 0 GBs
# [1] "index: 145/360"
# 0 GBs
# [1] "index: 146/360"
# 0 GBs
# [1] "index: 147/360"
# 0 GBs
# [1] "index: 148/360"
# 0 GBs
# [1] "index: 149/360"
# [1] "index: 150/360"
# 0 GBs
# [1] "index: 151/360"
# [1] "index: 152/360"
# 0 GBs
# [1] "index: 153/360"
# 0 GBs
# [1] "index: 154/360"
# 0 GBs
# [1] "index: 155/360"
# [1] "index: 156/360"
# 0 GBs
# [1] "index: 157/360"
# 0 GBs
# [1] "index: 158/360"
# 0 GBs
# [1] "index: 159/360"
# 0 GBs
# [1] "index: 160/360"
# 0 GBs
# [1] "index: 161/360"
# 0 GBs