import anndata
import os
import sfaira
import sys
from sfaira.data.dataloaders.databases import DatasetSuperGroupDatabases

# TODO:
# list collections
# list datasets
# 

COLLECTION_ID = sys.argv[1]

cache_path = os.path.join(".", "data")
dsg = sfaira.data.dataloaders.databases.DatasetSuperGroupDatabases(data_path = cache_path, cache_metadata = True)

#collecting each collection from dsg object
collections = [x.collection_id for x in dsg.dataset_groups]

# splitting into datasets
dsg.subset(key = "collection_id", values = COLLECTION_ID)

dsg.download()
dsg.load()
adata = dsg.adata_ls
print(adata)