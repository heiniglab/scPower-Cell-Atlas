package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

// TODO: to be extended for every type contained
type IDInstance struct {
	CellCount    int    `json:"cell_count"`
	CollectionID string `json:"collection_id"`
	DatasetID    string `json:"id"`
}

type DatasetCollection struct {
	DatasetCollections []DatasetInstance `json:"assets"`
}

type DatasetInstance struct {
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

	var (
		datasetCollection []IDInstance
		idCollection      []string
	)

	// embed our response body into specified struct
	json.Unmarshal(body, &datasetCollection)

	for i := range datasetCollection {
		idCollection = append(idCollection, datasetCollection[i].DatasetID)
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

func GetDownloadBody() ([]byte, string) {
	res, err := http.Post("https://api.cellxgene.cziscience.com/dp/v1/datasets/b74100ea-1a1a-486a-9cad-70ae44150935/asset/d3bc4de8-ed94-4a85-94db-7ccc21f61195",
		"application/json",
		nil)
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

	// prettify json body
	body_prettified, err := json.MarshalIndent(downloadInstance, "", "  ")
	if err != nil {
		fmt.Println(err)
	}

	downloadLink := downloadInstance.PresignedUrl

	return body_prettified, downloadLink
}

func main() {
	idCollection := IDExtractor()

	var h5adIdCollector []string

	for _, id := range idCollection {
		url := "https://api.cellxgene.cziscience.com/dp/v1/datasets/" + id + "/assets"
		h5adId := GetH5adId(url, "H5AD")
		h5adIdCollector = append(h5adIdCollector, h5adId)
	}

	fmt.Println(h5adIdCollector)
}
