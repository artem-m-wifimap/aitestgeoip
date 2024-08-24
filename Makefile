.PHONY: start ci download-db test

# Start the application
start:
	bundle exec dotenv thin start -p 4567

# Run CI tasks (tests and linting)
ci: test lint

# Run tests
test:
	bundle exec rspec

# Run linter
lint:
	bundle exec rubocop

# Download the latest MaxMind GeoLite2 database
download-db:
	mkdir -p ./app/bin
	curl -o ./app/bin/GeoLite2-City.mmdb.gz "https://cdn.jsdelivr.net/npm/geolite2-city@1.0.0/GeoLite2-City.mmdb.gz"
	gunzip -f ./app/bin/GeoLite2-City.mmdb.gz

# Install dependencies
install:
	bundle install

# Setup the project (install dependencies and download the database)
setup: install download-db