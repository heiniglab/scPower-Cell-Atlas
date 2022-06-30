package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

type Collector struct {
	Collections []Instance `json:"assets"`
}

type Instance struct {
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

func GetCollectionBody() ([]byte, string) {
	res, err := http.Get("https://api.cellxgene.cziscience.com/dp/v1/datasets/dd018fc0-8da7-4033-a2ba-6b47de8ebb4f/assets")
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
		collection Collector
		IDH5AD     string
	)
	json.Unmarshal(body, &collection)

	// prettify json body
	body_prettified, err := json.MarshalIndent(collection, "", "  ")
	if err != nil {
		fmt.Println(err)
	}

	for i := range collection.Collections {
		if collection.Collections[i].FileType == "H5AD" {
			IDH5AD = collection.Collections[i].ID
		}

	}

	return body_prettified, IDH5AD
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
	//_, IDH5AD := GetCollectionBody()

	body, _ := GetDownloadBody()

	fmt.Println(string(body))
}
