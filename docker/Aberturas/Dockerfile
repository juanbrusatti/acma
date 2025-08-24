# syntax=docker/dockerfile:1
# check=error=true

FROM ruby:3.3

# Instalar dependencias
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-client \
  curl \
  git \
  nodejs \
  npm

# Instalar yarn globalmente
RUN npm install -g yarn

# Crear directorio de la app
WORKDIR /app

# Copiar Gemfile primero para aprovechar cache
COPY ./Aberturas/Gemfile ./Aberturas/Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 4 --retry 3

# Copiar el resto del código
COPY ./Aberturas/ .

# Instalar Node.js dependencies si hay package.json
RUN if [ -f package.json ]; then yarn install; fi

# Precompilar assets con variables de entorno de producción
ENV RAILS_ENV=production
RUN bundle exec rails tailwindcss:build && \
    bundle exec rails assets:precompile

# Copiar entrypoint
COPY ./entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# Exponer puerto Rails
EXPOSE 3000

# Usar entrypoint custom
ENTRYPOINT ["entrypoint.sh"]

# Comando por defecto
CMD ["rails", "server", "-b", "0.0.0.0"]
