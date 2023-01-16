import anndata
import os
import sfaira

# used as a cache for downloads from the cellxgene data server
cache_path = os.path.join(".", "data")

# Interaction with database
dsg = sfaira.data.dataloaders.databases.DatasetSuperGroupDatabases(data_path=cache_path, cache_metadata=True)

# which collections are available from cellxgene
#dsg.show_summary()

# ID of each collection (data set group)
#print([x.collection_id for x in dsg.dataset_groups])

# For now target is selected as the first collection browsed
# https://cellxgene.cziscience.com/collections/{target_collections[i]}
target_collections = [x.collection_id for x in dsg.dataset_groups][0]
dsg.subset(key="collection_id", values=target_collections)
dataset_ids = list(dsg.datasets.keys())

# check if a given dataset-id is existing or not
string_to_check = "edc8d3fe-153c-4e3d-8be0-2108d30f8d70"

# if exists acting on particular dataset such as downloading or loading it
if string_to_check in dataset_ids:
    print(dsg.datasets[string_to_check])
else: 
    print(string_to_check + " is not in the list.")

