# Base image
FROM ruby:2.7.6

# Set environment variables
ENV LANG C.UTF-8
ENV RAILS_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
ENV CANONICAL_HOST localhost
ENV REPLY_HOSTNAME localhost
ENV CANONICAL_PORT 8080
ENV SUPPORT_EMAIL "support <support@localhost>"
ENV SMTP_DOMAIN localhost
ENV RACK_ATTACK_RATE_MULTPLIER 10

# Install dependencies
RUN apt-get update -qq && apt-get install -y nodejs postgresql-client yarn

# Install Chrome for e2e tests
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' && \
    apt-get update && \
    apt-get install -y google-chrome-stable

# Create a directory for the app
RUN mkdir /app
WORKDIR /app

# Add Gemfile and install gems
COPY ./Gemfile /app/Gemfile
COPY ./Gemfile.lock /app/Gemfile.lock
RUN bundle install

# Add package.json and install npm packages
COPY ./vue/package.json /app/vue/package.json
COPY ./vue/package-lock.json /app/vue/package-lock.json
RUN cd /app/vue && npm ci

# Copy the app code
COPY . /app

# Precompile assets
RUN cd /app/vue && npm run build && \
    bundle exec rake assets:precompile

# Expose the port for the Rails server
EXPOSE 8080

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "8080"]
