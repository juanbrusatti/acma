# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t aberturas .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name aberturas aberturas

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

FROM ruby:3.3

# Install dependencies
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-client \
  nodejs \
  yarn \
  git \
  curl

# Create app directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY ./Aberturas/Gemfile ./Aberturas/Gemfile.lock ./

# Install gems
RUN gem install bundler
RUN bundle install

# Copy the rest of the application code
COPY ./Aberturas/ .

# Precompile tailwindcss assets (only production)
RUN bundle exec rails tailwindcss:build
RUN bundle exec rails assets:precompile

# Entrypoint script to set up the environment
COPY ./entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# Set Rails port
EXPOSE 3000

# Use script as entrypoint
ENTRYPOINT ["entrypoint.sh"]

# Default command to run the Rails server
CMD ["rails", "server", "-b", "0.0.0.0"]
