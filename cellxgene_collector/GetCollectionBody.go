package cellxgene_collector

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

type Collector struct {
	Collections []Instance `json:"collections"`
}

type Instance struct {
	CreatedAt  float64 `json:"created_at"`
	Id         string  `json:"id"`
	Visibility string  `json:"visibility"`
}

func GetCollectionBody() ([]byte, []string) {
	res, err := http.Get("https://api.cellxgene.cziscience.com/dp/v1/collections")
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
		collection   Collector
		idCollection []string
	)
	json.Unmarshal(body, &collection)

	// prettify json body
	body_prettified, err := json.MarshalIndent(collection, "", "  ")
	if err != nil {
		fmt.Println(err)
	}

	for i := range collection.Collections {
		idCollection = append(idCollection, collection.Collections[i].Id)
	}

	return body_prettified, idCollection
}
