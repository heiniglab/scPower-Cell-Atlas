import anndata
import os
import sfaira
import sys
from sfaira.data.dataloaders.databases import DatasetSuperGroupDatabases

# TODO:
# list collections
# list datasets
# arguments to be taken from terminal

#COLLECTION_ID = sys.argv[1]

if __name__ == "__main__":
    cache_path = os.path.join(".", "data")
    dsg = DatasetSuperGroupDatabases(data_path = cache_path, cache_metadata = True)

    #collecting each collection from dsg object
    collections = [x.collection_id for x in dsg.dataset_groups]
    COLLECTION_ID = collections[0]

    # splitting into datasets
    dsg.subset(key = "collection_id", values = COLLECTION_ID)

    dsg.download()
    dsg.load()
    adata = dsg.adata_ls
    print(adata)