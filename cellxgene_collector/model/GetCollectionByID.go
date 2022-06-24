package cellxgene_collector

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
)

/*
	TODO:
	-----
	* Her yere json kodlarını gir
	* Boş gözüken ayırdığım structları başka datasetlerden bak
*/

type CollectorByID struct {
	AccessType                 string            `json:"access_type"`
	ContactEmail               string            `json:"contact_email"`
	ContactName                string            `json:"contact_name"`
	CreatedAt                  float64           `json:"created_at"`
	CuratorName                string            `json:"curator_name"`
	DataSubmissionPolicyNumber string            `json:"data_submission_policy_version"`
	Datasets                   []Dataset         `json:"datasets"`
	Description                string            `json:"description"`
	Genesets                   []Geneset         `json:"genesets"`
	ID                         string            `json:"id"`
	Links                      []Link            `json:"links"`
	Name                       string            `json:"name"`
	PublishedAt                float64           `json:"published_at"`
	PublisherMetadatas         PublisherMetadata `json:"publisher_metadata"`
	RevisedAt                  float64           `json:"revised_at"`
	UpdatedAt                  float64           `json:"updated_at"`
	Visibility                 string            `json:"visibility"`
}

/************************************/
type Dataset struct {
	Dataset []InnerDataset
}

type InnerDataset struct {
	Assays               []CommonStruct      `json:"assay"`
	CellCount            int                 `json:"cell_count"`
	CellTypes            []CommonStruct      `json:"cell_type"`
	CollectionID         string              `json:"collection_id"`
	CollectionVisibility string              `json:"collection_visibility"`
	CreatedAt            float64             `json:"created_at"`
	DatasetAssets        []DatasetAsset      `json:"dataset_assets"`
	DatasetDeployments   []DatasetDeployment `json:"dataset_deployments"`
	DevelopmentStages    []CommonStruct      `json:"development_stage"`
	Diseases             []CommonStruct      `json:"disease"`
	Ethnicities          []CommonStruct      `json:"ethnicity"`
	ID                   string              `json:"id"`
	IsPrimaryData        string              `json:"is_primary_data"`
	IsValid              bool                `json:"is_valid"`
	LinkedGenetics       []LinkedGenetic     `json:"linked_genesets"`
	MeanGenesPerCell     float64             `json:"mean_genes_per_cell"`
	Name                 string              `json:"name"`
	Organisms            []CommonStruct      `json:"organism"`
	ProcessingStatus     ProcessingStatus    `json:"processing_status"`
	Published            bool                `json:"published"`
	PublishedAt          float64             `json:"published_at"`
	RevisedAt            float64             `json:"revised_at"`
	Revision             int                 `json:"revision"`
	SchemaVersion        string              `json:"schema_version"`
	Sex                  []CommonStruct      `json:"sex"`
	Tissues              []CommonStruct      `json:"tissue"`
	Tombstone            bool                `json:"tombstone"`
	UpdatedAt            float64             `json:"updated_at"`
	XNormalization       string              `json:"x_normalization"`
}

type DatasetAsset struct {
	CreatedAt     float64 `json:"created_at"`
	DatasetID     string  `json:"dataset_id"`
	Filename      string  `json:"filename"`
	Filetype      string  `json:"filetype"`
	ID            string  `json:"id"`
	S3URI         string  `json:"s3_uri"`
	UpdatedAt     float64 `json:"updated_at"`
	UserSubmitted bool    `json:"user_submitted"`
}

type DatasetDeployment struct {
	URL string `json:"url"`
}

type CommonStruct struct {
	Label          string `json:"label"`
	OntologyTermID string `json:"ontology_term_id"`
}

type LinkedGenetic struct{}

type ProcessingStatus struct {
	CreatedAt        float64 `json:"created_at"`
	CxgStatus        string  `json:"cxg_status"`
	DatasetID        string  `json:"dataset_id"`
	H5adStatus       string  `json:"h5ad_status"`
	ID               string  `json:"id"`
	ProcessingStatus string  `json:"processing_status"`
	RdsStatus        string  `json:"rds_status"`
	UpdatedAt        float64 `json:"updated_at"`
	UploadProgress   float64 `json:"upload_progress"`
	UploadStatus     string  `json:"upload_status"`
	ValidationStatus string  `json:"validation_status"`
}

/************************************/

type Geneset struct {
}

/************************************/

type Link struct {
	LinkName string `json:"link_name"`
	LinkType string `json:"link_type"`
	LinkURL  string `json:"link_url"`
}

/************************************/

type PublisherMetadata struct {
	Metadata InnerMetadata `json:"publisher_metadata"`
}

type InnerMetadata struct {
	Authors        []Author `json:"authors"`
	Dates          []string `json:"dates"`
	IsPreprint     bool     `json:"is_preprint"`
	Journal        string   `json:"journal"`
	PublishedDay   int      `json:"published_day"`
	PublishedMonth int      `json:"published_month"`
	PublishedYear  int      `json:"published_year"`
}

type Author struct {
	Family string `json:"family"`
	Given  string `json:"given"`
}

func CreateRequest(id string) {
	url := "https://api.cellxgene.cziscience.com/dp/v1/collections/" + id

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

	var dataset CollectorByID

	json.Unmarshal(body, &dataset)

	// prettify json body
	body_prettified, err := json.MarshalIndent(dataset, "", "  ")
	if err != nil {
		fmt.Println(err)
	}

	fmt.Println(string(body_prettified))

}

func GetCollectionByID(idCollection []string) {

	/*for _, id := range idCollection {
		fmt.Println(id)
	}*/

	CreateRequest(idCollection[0])
}
