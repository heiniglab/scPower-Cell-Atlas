package main

import (
	"apiTrial/models"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"
)

func timeStampToDatetime(timestamp string) {
	v := strings.Split(timestamp, ".")
	if len(v[1]) > 0 {
		for len(v[1]) < 9 {
			v[1] += "0"
		}
	}
	a, _ := strconv.ParseInt(v[0], 10, 64)
	b, _ := strconv.ParseInt(v[1], 10, 64)
	t := time.Unix(a, b).UnixNano()
	fmt.Printf("The time is: %d which is: %s\n", t, time.Unix(0, t).UTC())
}

// Firstly scraping every dataset involved in the endpoint
// Then extracting "id" information out of each dataset
// return: idCollection []string
func IDExtractor() ([]byte, []string) {
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

	body_prettified, err := json.MarshalIndent(datasetCollection, "", "  ")
	if err != nil {
		fmt.Println(err)
	}

	return body_prettified, idCollection
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

	var IDH5AD string
	collection := &models.DatasetCollection{}

	// embed our response body into specified struct
	json.Unmarshal(body, collection)

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

	downloadInstance := &models.DownloadInstance{}

	json.Unmarshal(body, downloadInstance)

	downloadLink := downloadInstance.PresignedUrl

	return downloadLink
}

func main() {
	datasetCollection, idCollection := IDExtractor()

	var downloadUrlCollector []string

	for _, id := range idCollection {
		baseUrl := "https://api.cellxgene.cziscience.com/dp/v1/datasets/" + id + "/assets"
		h5adId := GetH5adId(baseUrl, "H5AD")
		completeUrl := "https://api.cellxgene.cziscience.com/dp/v1/datasets/" + id + "/asset/" + h5adId
		downloadUrl := GetDownloadUrl(completeUrl)

		downloadUrlCollector = append(downloadUrlCollector, downloadUrl)
	}

	fmt.Println(string(datasetCollection))
}
