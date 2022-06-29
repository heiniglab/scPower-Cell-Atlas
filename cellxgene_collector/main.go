package main

import (
	cellxgene_collector "helmholtz/cellxgene_collector/model"
)

func main() {
	_, idCollection := cellxgene_collector.GetCollectionBody()

	cellxgene_collector.GetCollectionByID(idCollection)
}
