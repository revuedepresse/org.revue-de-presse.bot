SHELL:=/bin/bash

.PHONY: install install-javascript-runtime install-ruby-runtime install-browser install-twurl install-website-screenshot-capture-cli install-web-browser

.PHONY: tweet

AUTH_TOKEN ?= ''
DATE ?= ''

capture-dated-website-screenshots-collection: ## Capture revue-de-presse.org website screenshots e.g. DATE=$(date -I) make capture-website-screenshot
	@bash -c '. ./tweet.sh && _capture_dated_website_screenshots_collection '"${DATE}" | tee --append ./var/log/capturing-website-screenshot.log

capture-dated-website-screenshots-since: ## Capture revue-de-presse.org website screenshots since a given date e.g. DATE=$(date -I) make capture-dated-website-screenshots-since
	@bash -c '. ./tweet.sh && _capture_dated_website_screenshots_since '"${DATE}" | tee --append ./var/log/capturing-website-screenshots-since.log

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

install-package-manager: ## Install package manager (asdf)
	@bash -c '. ./tweet.sh && install_package_manager_asdf' | tee --append ./var/log/installing-package-manager.log

install-javascript-runtime: install-package-manager ## Install JavaScript runtime (node.js)
	@bash -c '. ./tweet.sh && install_javascript_runtime_nodejs' 2>&1 | tee --append ./var/log/installing-javascript-runtime.log

install-jq: ## Install jq
	@apt install jq --assume-yes || sudo apt install jq --assume-yes

install-ruby-runtime: install-package-manager ## Install Ruby runtime
	@bash -c '. ./tweet.sh && install_ruby_runtime' 2>&1 | tee --append ./var/log/installing-ruby-runtime.log

install-twitter-client: install-ruby-runtime ## Install Twitter client (twurl)
	@bash -c '. ./tweet.sh && install_twitter_client_twurl' 2>&1 | tee --append ./var/log/installing-twitter-client.log

install-web-browser: ## Install web browser (Chrome)
	@bash -c '. ./tweet.sh && install_web_browser' 2>&1 | tee --append ./var/log/installing-web-browser.log

install-website-capture-cli: install-javascript-runtime install-web-browser  ## Install website capture CLI
	@bash -c '. ./tweet.sh && install_website_screenshot_capture_cli' 2>&1 | tee --append ./var/log/installing-website-screenshot-capture-cli-runtime.log

install: install-jq install-twitter-client install-website-capture-cli ## Install dependencies

newsletter: ## Add items to a newsletter via getrevue.co API e.g. REVUE_AUTH_TOKEN='co.getrevue.token' AUTH_TOKEN='org_example_api.token' make newsletter 
	@bash -c '. ./tweet.sh && prepublish_newsletter '"${DATE}" | tee --append ./var/log/publishing.log

tweet: ## Post a tweet via Twitter API e.g. AUTH_TOKEN='org_example_api.token' make tweet
	@bash -c '. ./tweet.sh && tweet '"${DATE}" | tee --append ./var/log/tweeting.log

