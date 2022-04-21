package main

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

func CollectGeneralInfo() {
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

	var instance Collector
	json.Unmarshal(body, &instance)

	// prettify json
	b, err := json.MarshalIndent(instance, "", "  ")
	if err != nil {
		fmt.Println(err)
	}

	fmt.Print(string(b))
}

func main() {
	CollectGeneralInfo()
}
