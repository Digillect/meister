FROM ruby:2.6-alpine3.8

RUN \
    apk update && apk upgrade && \
    apk --no-cache add make gcc libc-dev && \
    rm -rf /var/cache/apk/*

# Install Bundler 2.0
RUN gem install bundler

COPY gems.* /app/
WORKDIR /app
RUN bundle install --without development test

COPY main.rb /app/
COPY lib /app/lib/

CMD ["/usr/bin/env", "ruby", "/app/main.rb"]
