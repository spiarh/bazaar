FROM alpine:latest

RUN apk add ruby ruby-devel ruby-bundler

COPY Gemfile* *.gemspec ./
COPY lib/pharos/version.rb ./lib/pharos/
RUN bundle install

COPY . .

CMD ["./bin/pharos-cluster"]

