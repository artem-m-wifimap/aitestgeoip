# GeoIP Lookup Service

This is a simple Sinatra-based web service that provides GeoIP lookup functionality.

## Prerequisites

- Ruby (version 2.7 or higher recommended)
- Bundler
- Make (for using Makefile commands)

## Setup

1. Clone the repository:
   ```
   git clone <repository-url>
   cd <repository-name>
   ```

2. Set up the project using the Makefile:
   ```
   make setup
   ```
   This command will install dependencies and download the GeoLite2 database.

3. Set up the environment:
   - Copy the `.env.example` file to `.env`:
     ```
     cp .env.example .env
     ```
   - Open the `.env` file and adjust the values if needed:
     ```
     RACK_ENV=development
     GEOIP_DB_PATH=./app/bin/GeoLite2-City.mmdb
     ```
     - `RACK_ENV`: Set to `development` for local development, `test` for running tests, or `production` for production environment.
     - `GEOIP_DB_PATH`: Path to the GeoLite2 City database file. The default path is set to `./app/bin/GeoLite2-City.mmdb`.

4. (Optional) If you want to use a different path for the GeoLite2 database, update the `GEOIP_DB_PATH` in your `.env` file and ensure the database file is present at that location.

## Running the Application

Start the server using the Makefile command:

```
make start
```

The application will be available at `http://localhost:4567`.

## Usage

To lookup an IP address, make a GET request to the `/geoip` endpoint:

```
http://localhost:4567/geoip?ip=8.8.8.8
```

If no IP is provided, it will use the requester's IP address.

## Development

### Running Tests

To run the test suite:
```
make test
```

### Linting

To run the linter (RuboCop):
```
make lint
```

### CI Tasks

To run all CI tasks (tests, linting, and dependency checks):
```
make ci
```

### Checking Dependencies

To check for outdated or vulnerable dependencies:
```
bundle exec bundle-audit check --update
```

This command will update the Ruby Advisory Database and check your dependencies against it.

### Updating the GeoLite2 Database

To download the latest version of the MaxMind GeoLite2 database:
```
make download-db
```

## Makefile Commands

The project includes a Makefile with the following commands:

- `make start`: Starts the application
- `make ci`: Runs all CI tasks (tests, linting, and dependency checks)
- `make test`: Runs the test suite
- `make lint`: Runs the linter (RuboCop)
- `make download-db`: Downloads the latest MaxMind GeoLite2 database
- `make install`: Installs project dependencies
- `make setup`: Sets up the project (installs dependencies and downloads the database)
- `make check-deps`: Checks for outdated or vulnerable dependencies

## License

This project is open-source and available under the MIT License.

Note: Ensure you comply with MaxMind's licensing terms when using the GeoLite2 database.