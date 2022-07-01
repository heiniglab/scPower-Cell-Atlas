package models

type DatasetMiniInstance struct {
	CellCount    int    `json:"cell_count"`
	CollectionID string `json:"collection_id"`
	DatasetID    string `json:"id"`
}

type DatasetInstance []DatasetMiniInstance
