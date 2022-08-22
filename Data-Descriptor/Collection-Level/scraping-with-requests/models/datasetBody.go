package models

type DatasetInstance []DatasetMiniInstance

type DatasetMiniInstance struct {
	Assay                     []CommonObject `json:"assay"`
	CellCount                 int            `json:"cell_count"`
	CellType                  []CommonObject `json:"cell_type"`
	CollectionID              string         `json:"collection_id"`
	DevelopmentStage          []CommonObject `json:"development_stage"`
	DevelopmentStageAncestors []string       `json:"development_stage_ancestors"`
	Disease                   []CommonObject `json:"disease"`
	Etnicity                  []CommonObject `json:"ethnicity"`
	CXGUrl                    string         `json:"explorer_url"`
	DatasetID                 string         `json:"id"`
	MeanGenesPerCell          float64        `json:"mean_genes_per_cell"`
	Name                      string         `json:"name"`
	Organism                  []CommonObject `json:"organism"`
	PublishedAt               float64        `json:"published_at"`
	RevisedAt                 float64        `json:"revised_at"`
	Sex                       []CommonObject `json:"sex"`
	Tissue                    []CommonObject `json:"tissue"`
}

type CommonObject struct {
	Label          string `json:"label"`
	OntologyTermID string `json:"ontology_term_id"`
}
