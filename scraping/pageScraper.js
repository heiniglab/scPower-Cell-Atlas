const scraperObject = {
    url: 'https://cellxgene.cziscience.com/',

    async scraper(browser){
		let regexForLink = /href=\\["']([^"']*)["']/
		let alternativeRegex = /href="([^"]*)/

		let page = await browser.newPage();

		console.log(`Navigating to ${this.url}...`);

		// Navigate to the selected page
		await page.goto(this.url);

		// Wait for the required DOM to be rendered
		await page.waitForSelector('[data-icon=chevron-down]');		  

		// Get the link to all the required books
		let pageContent = await page.evaluate(() => {
			// Extract the links from the data
			const tds = Array.from(document.querySelectorAll('table tbody tr td'))
			const pageTextContent = tds.map(td => td.innerText)

			// Firstly convert object into string format
			// Then parse it by [""] character set to separate each dataset info
			jsonPrettified = JSON.stringify(pageTextContent).split(/""/)

			// Loop through each dataset and seperate them into specific
			// informations such as Title, Disease, Assay, Organism, Cells	
			var dict = [];

			jsonPrettified.forEach(dataset => {
				let datasetInfoSplitted = dataset.split("\",\"")
				let titleSplitted = datasetInfoSplitted[0].split("\\n")

				dict.push({
					Title: 			 titleSplitted[0].substr(2),
					CollectionTitle: titleSplitted[1],
					Tissue: 		 "tissue",
					Disease: 		 "disease",
					Assay: 			 "assay",
					Organism: 		 datasetInfoSplitted[4],
					Cells: 			 datasetInfoSplitted[5]
				});
			});

			return dict
		});

		return pageContent
    }
}

module.exports = scraperObject;