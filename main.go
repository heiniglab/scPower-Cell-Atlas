package main

import (
	"helmholtz/cellxgene_collector"
)

func main() {
	_, idCollection := cellxgene_collector.GetCollectionBody()

	cellxgene_collector.GetCollectionByID(idCollection)
}
