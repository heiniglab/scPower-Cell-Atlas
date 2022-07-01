package main

import (
	"apiTrial/models"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

type DatasetCollection struct {
	DatasetCollections []UpLayerDatasetInstance `json:"assets"`
}

type UpLayerDatasetInstance struct {
	DatasetID string `json:"dataset_id"`
	FileType  string `json:"filetype"`
	ID        string `json:"id"`
	S3Uri     string `json:"s3_uri"`
}

type DownloadInstance struct {
	DatasetID    string `json:"dataset_id"`
	Filename     string `json:"file_name"`
	FileSize     int    `json:"file_size"`
	PresignedUrl string `json:"presigned_url"`
}

// Firstly scraping every dataset involved in the endpoint
// Then extracting "id" information out of each dataset
// return: idCollection []string
func IDExtractor() []string {
	// general endpoints:
	// https://api.cellxgene.cziscience.com/dp/v1/collections/index

	// creating GET request towards specified url
	url := "https://api.cellxgene.cziscience.com/dp/v1/datasets/index"

	res, err := http.Get(url)
	if err != nil {
		log.Fatalln(err)
	}
	defer res.Body.Close()

	// read body and parse the json
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		log.Fatalln(err)
	}

	var idCollection []string
	datasetCollection := &models.DatasetInstance{}

	// embed our response body into specified struct
	json.Unmarshal(body, datasetCollection)

	for _, dataset := range *datasetCollection {
		idCollection = append(idCollection, dataset.DatasetID)
	}

	return idCollection
}

// Extracting fileType dependent url for a single dataset
// url: https://api.cellxgene.cziscience.com/dp/v1/datasets/[ID]/assets
// ID: obtained collection from IDExtractor function
// fileType: H5AD, RDS, CXG
// return: IDH5AD string
func GetH5adId(url string, fileType string) string {

	// creating GET request towards specified url
	res, err := http.Get(url)
	if err != nil {
		log.Fatalln(err)
	}
	defer res.Body.Close()

	// read body and parse the json
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		log.Fatalln(err)
	}

	var (
		collection DatasetCollection
		IDH5AD     string
	)

	// embed our response body into specified struct
	json.Unmarshal(body, &collection)

	// prettify json body
	/*body_prettified, err := json.MarshalIndent(collection, "", "  ")
	if err != nil {
		fmt.Println(err)
	}*/

	// extract only
	for i := range collection.DatasetCollections {
		if collection.DatasetCollections[i].FileType == fileType {
			IDH5AD = collection.DatasetCollections[i].ID
		}

	}

	return IDH5AD
}

// After having both "dataset_id" and "H5AD" format related id
// we have the complete url for reaching out to the aws with a proper request
// url: https://api.cellxgene.cziscience.com/dp/v1/datasets/[ID]/asset/[IDH5AD]
// return: presigned_url (which is the download link for a single dataset)
func GetDownloadUrl(url string) string {

	res, err := http.Post(url, "application/json", nil)
	if err != nil {
		log.Fatalln(err)
	}
	defer res.Body.Close()

	// read body and parse the json
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		log.Fatalln(err)
	}

	var downloadInstance DownloadInstance

	json.Unmarshal(body, &downloadInstance)

	downloadLink := downloadInstance.PresignedUrl

	return downloadLink
}

func main() {
	idCollection := IDExtractor()

	var downloadUrlCollector []string

	for _, id := range idCollection {
		baseUrl := "https://api.cellxgene.cziscience.com/dp/v1/datasets/" + id + "/assets"
		h5adId := GetH5adId(baseUrl, "H5AD")
		completeUrl := "https://api.cellxgene.cziscience.com/dp/v1/datasets/" + id + "/asset/" + h5adId
		downloadUrl := GetDownloadUrl(completeUrl)

		downloadUrlCollector = append(downloadUrlCollector, downloadUrl)
	}

	fmt.Println(downloadUrlCollector)
}
