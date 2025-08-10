# ACMA
A Company that Makes Aberturas

## Technology Stack

* **Backend:** Ruby on Rails 8.0.2
* **Language:** Ruby 3.3.1
* **Database:** PostgreSQL ()

# Prerequisites

Before you begin, ensure you have the following installed:

* Ruby 3.3.1 (using a version manager like `rbenv` or `rvm` is recommended)
* Bundler (`gem install bundler`)
* PostgreSQL
* Git for version management

# Installation

Follow these steps to get the project running in your local environment:

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/juanbrusatti/acma.git](https://github.com/juanbrusatti/acma.git)
    cd acma
    ```

2.  **Install Ruby gems:**
    ```bash
    cd Aberturas
    bundle install
    ```

3.  **Configure the database:**
    * Copy the example configuration file:
        ```bash
        cp config/database.yml.example config/database.yml
        ```
    * Edit `config/database.yml` with your database credentials if necessary (especially for the `development` and `test` environments).

4.  **Create and migrate the database:**
    ```bash
    rails db:create
    rails db:migrate
    ```

5.  **(Optional) Load initial data (seeds):**
    ```bash
    rails db:seed
    ```

6.  **Set up the AI backend**

## Running Tests

To run the automated test suite:

  ```bash
  rails test
  ```
Ensure all tests pass before proposing changes.