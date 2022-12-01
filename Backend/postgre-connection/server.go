package main

import (
	"database/sql"
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	_ "github.com/lib/pq"

	"github.com/blockloop/scan"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/template/html"
)

type DatasetInstance []DatasetMiniInstance

type DatasetMiniInstance struct {
	Assay            []CommonObject `json:"assay"`
	CellCount        int            `json:"cell_count"`
	CellType         []CommonObject `json:"cell_type"`
	CollectionID     string         `json:"collection_id"`
	DevelopmentStage []CommonObject `json:"development_stage"`
	Disease          []CommonObject `json:"disease"`
	Etnicity         []CommonObject `json:"ethnicity"`
	CXGUrl           string         `json:"explorer_url"`
	DatasetID        string         `json:"id"`
	MeanGenesPerCell float64        `json:"mean_genes_per_cell"`
	Name             string         `json:"name"`
	Organism         []CommonObject `json:"organism"`
	PublishedAt      float64        `json:"published_at"`
	RevisedAt        float64        `json:"revised_at"`
	Sex              []CommonObject `json:"sex"`
	Tissue           []CommonObject `json:"tissue"`
}

type DatasetMiniInstancePrimitives struct {
	CellCount        int     `json:"cell_count"`
	CollectionID     string  `json:"collection_id"`
	CXGUrl           string  `json:"explorer_url"`
	DatasetID        string  `json:"id"`
	MeanGenesPerCell float64 `json:"mean_genes_per_cell"`
	Name             string  `json:"name"`
	PublishedAt      float64 `json:"published_at"`
	RevisedAt        float64 `json:"revised_at"`
}

type DatasetMiniInstanceCommonObjects struct {
	Assay            []CommonObject `json:"assay"`
	CellType         []CommonObject `json:"cell_type"`
	DevelopmentStage []CommonObject `json:"development_stage"`
	Disease          []CommonObject `json:"disease"`
	Etnicity         []CommonObject `json:"ethnicity"`
	Organism         []CommonObject `json:"organism"`
	Sex              []CommonObject `json:"sex"`
	Tissue           []CommonObject `json:"tissue"`
}

type CommonObject struct {
	Label          string `json:"label"`
	OntologyTermID string `json:"ontology_term_id"`
}

func IDExtractor() (DatasetInstance, []string) {
	// general endpoints:
	// https://api.cellxgene.cziscience.com/dp/v1/collections/index

	// creating GET request towards specified url
	url := "https://api.cellxgene.cziscience.com/dp/v1/datasets/index"

	res, err := http.Get(url)
	ErrCheck("http get on url", err)
	defer res.Body.Close()

	// read body and parse the json
	body, err := ioutil.ReadAll(res.Body)
	ErrCheck("read body and parse the json", err)

	var (
		idCollection      []string
		datasetCollection DatasetInstance
	)

	// embed our response body into specified struct
	json.Unmarshal(body, &datasetCollection)

	for _, dataset := range datasetCollection {
		idCollection = append(idCollection, dataset.DatasetID)
	}

	return datasetCollection, idCollection
}

// returns JSON encoding for the CommonObject struct
func (c CommonObject) Value() (driver.Value, error) {
	return json.Marshal(c)
}

// parses JSON from database to Go struct
func (c *CommonObject) Scan(value interface{}) error {
	b, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}
	return json.Unmarshal(b, &c)
}

func ErrCheck(stage string, err error) {
	if err != nil {
		log.Fatalf("%s %v\n", stage, err)
	}
}

func indexHandler(c *fiber.Ctx, db *sql.DB) error {
	var primitiveCollection []DatasetMiniInstancePrimitives
	queryPrimitive := "SELECT \"CellCount\", \"CollectionID\", \"CXGUrl\"," +
		"\"DatasetID\", \"MeanGenesPerCell\", \"Name\"," +
		"\"PublishedAt\", \"RevisedAt\" FROM todos"
	primitiveRows, err := db.Query(queryPrimitive)
	ErrCheck("primitive types query read", err)
	defer primitiveRows.Close()

	err = scan.Rows(&primitiveCollection, primitiveRows)
	ErrCheck("primitive types scan rows", err)

	fmt.Printf("%#v", primitiveCollection)

	// Multiple rows of primitive types
	/*err = scan.Rows(&todos, rows)
	ErrCheck("deneme1", err)
	*/

	/*var ws []CommonObject
	for rows.Next() {
		w := CommonObject{}
		err := rows.Scan(&w.Label)
		ErrCheck("deneme2", err)
		ws = append(ws, w)
	}*/

	return c.Render("index", fiber.Map{
		"Todos": primitiveCollection,
	})
}

func postHandler(c *fiber.Ctx, db *sql.DB) error {
	datasetCollection, _ := IDExtractor()
	/*newTodo := DatasetInstance{}
	if err := c.BodyParser(&newTodo); err != nil {
		log.Printf("An error occured: %v", err)
		return c.SendString(err.Error())
	}*/

	for _, dataset := range datasetCollection {
		statement := "INSERT into todos VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)"
		assayValue, _ := json.Marshal(dataset.Assay)
		cellTypeValue, _ := json.Marshal(dataset.CellType)
		developmentStageValue, _ := json.Marshal(dataset.DevelopmentStage)
		diseaseValue, _ := json.Marshal(dataset.Disease)
		etnicityValue, _ := json.Marshal(dataset.Etnicity)
		organismValue, _ := json.Marshal(dataset.Organism)
		sexValue, _ := json.Marshal(dataset.Sex)
		tissueValue, _ := json.Marshal(dataset.Tissue)
		_, err := db.Exec(statement,
			assayValue,
			dataset.CellCount,
			cellTypeValue,
			dataset.CollectionID,
			developmentStageValue,
			diseaseValue,
			etnicityValue,
			dataset.CXGUrl,
			dataset.DatasetID,
			dataset.MeanGenesPerCell,
			dataset.Name,
			organismValue,
			dataset.PublishedAt,
			dataset.RevisedAt,
			sexValue,
			tissueValue)

		ErrCheck("An error occured while executing query", err)
	}

	return c.Redirect("/")
}

func putHandler(c *fiber.Ctx, db *sql.DB) error {
	olditem := c.Query("olditem")
	newitem := c.Query("newitem")
	db.Exec("UPDATE todos SET item=$1 WHERE item=$2", newitem, olditem)
	return c.Redirect("/")
}

func deleteHandler(c *fiber.Ctx, db *sql.DB) error {
	todoToDelete := c.Query("item")
	db.Exec("DELETE from todos WHERE item=$1", todoToDelete)
	return c.SendString("deleted")
}

func main() {
	connStr := "postgresql://postgres:asdasd12x@127.0.0.1:5432/todos?sslmode=disable"

	// Connect to database
	db, err := sql.Open("postgres", connStr)
	ErrCheck("creating connection with database", err)
	defer db.Close()

	engine := html.New("./views", ".html")
	app := fiber.New(fiber.Config{
		Views: engine,
	})

	app.Get("/", func(c *fiber.Ctx) error {
		return indexHandler(c, db)
	})

	app.Post("/", func(c *fiber.Ctx) error {
		return postHandler(c, db)
	})

	app.Put("/update", func(c *fiber.Ctx) error {
		return putHandler(c, db)
	})

	app.Delete("/delete", func(c *fiber.Ctx) error {
		return deleteHandler(c, db)
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "3000"
	}

	app.Static("/", "./public")
	log.Fatalln(app.Listen(fmt.Sprintf(":%v", port)))
}
