FROM ruby:3.2.11

ARG PORTAL_TOKEN_SECRET
ENV PORTAL_TOKEN_SECRET=${PORTAL_TOKEN_SECRET}
ENV RAILS_ENV=development
ENV BUNDLE_PATH=/usr/local/bundle

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends libpq-dev postgresql-client \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /srv/permit-desk

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

EXPOSE 3000
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
