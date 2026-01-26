# syntax=docker/dockerfile:1

FROM ruby:3.3

# Instalar dependencias incluyendo wkhtmltopdf para PDFs y Python para el optimizador
RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  postgresql-client \
  curl \
  git \
  nodejs \
  npm \
  python3 \
  python3-pip \
  python3-dev \
  python3-venv \
  xvfb \
  wget \
  fontconfig \
  libxrender1 \
  xfonts-75dpi \
  xfonts-base \
  libfreetype6-dev \
  libpng-dev

# Instalar wkhtmltopdf manualmente
RUN wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-3/wkhtmltox_0.12.6.1-3.bookworm_amd64.deb && \
    dpkg -i wkhtmltox_0.12.6.1-3.bookworm_amd64.deb || apt-get install -f -y && \
    rm wkhtmltox_0.12.6.1-3.bookworm_amd64.deb

# Instalar yarn globalmente
RUN npm install -g yarn

# Crear directorio de la app
WORKDIR /app

# Copiar Gemfile primero para aprovechar cache
COPY docker/Aberturas/Gemfile docker/Aberturas/Gemfile.lock /app/
RUN gem install bundler && bundle install --jobs 4 --retry 3

# Copiar el resto del código
COPY docker/Aberturas/ /app/

# Instalar Node.js dependencies si hay package.json
RUN if [ -f package.json ]; then yarn install; fi

# Instalar dependencias Python del optimizador
COPY docker/Aberturas/lib/optimizer/requirements.txt /tmp/requirements.txt
RUN python3 -m venv /opt/venv
RUN . /opt/venv/bin/activate && pip install --no-cache-dir -r /tmp/requirements.txt
ENV PATH="/opt/venv/bin:$PATH"

# Precompilar assets con variables de entorno de producción
ENV RAILS_ENV=production
ARG RAILS_MASTER_KEY_BUILD=94d64d6202fefd0e6ec3305d03767cbe
ENV RAILS_MASTER_KEY=$RAILS_MASTER_KEY_BUILD
ENV SECRET_KEY_BASE=dummy_key_for_build_only
RUN bundle exec rails tailwindcss:build && \
    bundle exec rails assets:precompile

# Copiar entrypoint
COPY docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# Exponer puerto Rails
EXPOSE 3000

# Usar entrypoint custom
ENTRYPOINT ["entrypoint.sh"]

# Comando por defecto
CMD ["rails", "server", "-b", "0.0.0.0"]
