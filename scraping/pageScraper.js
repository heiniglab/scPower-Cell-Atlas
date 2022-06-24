const scraperObject = {
    url: 'https://cellxgene.cziscience.com/',

    async scraper(browser){
		let regexForLink = /href=\\["']([^"']*)["']/
		let alternativeRegex = /href="([^"]*)/
		// href=\\["']([^"']*)["']
		let page = await browser.newPage();

		console.log(`Navigating to ${this.url}...`);

		// Navigate to the selected page
		await page.goto(this.url);

		// Wait for the required DOM to be rendered
		await page.waitForSelector('.bp3-button-text');		  

		// Get the link to all the required books
		let pageContent = await page.evaluate(() => {
			// Extract the links from the data
			const tds = Array.from(document.querySelectorAll('table tbody tr td'))
			const url = tds.map(td => td.innerText)
			console.log(JSON.stringify(tds.map(td => td.innerHTML)))
    		return url
		});

		// Firstly convert object into string format
		// Then parse it by [""] character set to separate each dataset info
		pageContent = JSON.stringify(pageContent).split(/""/)

		return pageContent
    }
}

module.exports = scraperObject;