package models

type DatasetCollection struct {
	DatasetCollections []UpLayerDatasetInstance `json:"assets"`
}

type UpLayerDatasetInstance struct {
	DatasetID string `json:"dataset_id"`
	FileType  string `json:"filetype"`
	ID        string `json:"id"`
	S3Uri     string `json:"s3_uri"`
}
