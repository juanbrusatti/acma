# syntax=docker/dockerfile:1

FROM ruby:3.3

# Instalar dependencias incluyendo wkhtmltopdf para PDFs
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-client \
  curl \
  git \
  nodejs \
  npm \
  xvfb \
  wget \
  fontconfig \
  libxrender1 \
  xfonts-75dpi \
  xfonts-base

# Instalar wkhtmltopdf manualmente
RUN wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb && \
    dpkg -i wkhtmltox_0.12.6.1-3.bookworm_amd64.deb || apt-get install -f -y && \
    rm wkhtmltox_0.12.6.1-3.bookworm_amd64.deb

# Instalar yarn globalmente
RUN npm install -g yarn

# Crear directorio de la app
WORKDIR /app

# Copiar Gemfile primero para aprovechar cache
COPY ./Aberturas/Gemfile ./Aberturas/Gemfile.lock /app/
RUN gem install bundler && bundle install --jobs 4 --retry 3

# Copiar el resto del código
COPY ./Aberturas/ /app/

# Instalar Node.js dependencies si hay package.json
RUN if [ -f package.json ]; then yarn install; fi

# Precompilar assets con variables de entorno de producción
ENV RAILS_ENV=production
ARG RAILS_MASTER_KEY_BUILD=94d64d6202fefd0e6ec3305d03767cbe
ENV RAILS_MASTER_KEY=$RAILS_MASTER_KEY_BUILD
ENV SECRET_KEY_BASE=dummy_key_for_build_only
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
