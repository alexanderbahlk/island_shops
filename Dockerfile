# syntax = docker/dockerfile:1

ARG RUBY_VERSION=3.2.0
FROM ruby:$RUBY_VERSION-slim

WORKDIR /rails

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev curl && \
    rm -rf /var/lib/apt/lists/*

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy app
COPY . .

# Rails 7 handles assets better - precompile during build
RUN RAILS_ENV=production SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# Create non-root user
RUN useradd -m rails && chown -R rails:rails /rails
USER rails

EXPOSE 3000

# Modern Rails 7 startup
# CMD ["sh", "-c", "bundle exec rails db:prepare && bundle exec rails server -b 0.0.0.0"]
CMD ["./bin/docker-entrypoint"]