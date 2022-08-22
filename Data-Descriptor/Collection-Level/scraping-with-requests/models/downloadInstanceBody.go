package models

type DownloadInstance struct {
	DatasetID    string `json:"dataset_id"`
	Filename     string `json:"file_name"`
	FileSize     int    `json:"file_size"`
	PresignedUrl string `json:"presigned_url"`
}
