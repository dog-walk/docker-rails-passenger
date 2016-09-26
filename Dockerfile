# Set initial image
FROM kozhin/rails:latest

# Set maintainer and image indo
MAINTAINER Konstantin Kozhin <konstantin@profitco.ru>
LABEL Description="This image runs Ruby on Rails server for production" Vendor="ProfitCo" Version="1.0"

# Install Passenger repositories
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
RUN apt-get install -y apt-transport-https ca-certificates

# Add our APT repository
RUN sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger jessie main > /etc/apt/sources.list.d/passenger.list'
RUN apt-get update

# Install Passenger + Nginx
RUN apt-get install -y nginx-extras passenger

# Copy configuration files for nginx
COPY nginx.conf /etc/nginx/
COPY rails-application.conf /etc/nginx/sites-enabled/

# Create and set application folder
RUN mkdir -p /app
WORKDIR /app

# Prepare to build gems
ONBUILD COPY Gemfile /app/
ONBUILD COPY Gemfile.lock /app/

# Update bash and install Rails application gems
ONBUILD RUN bash -c "source ~/.bash_profile \
&& bundle install \
&& RAILS_ENV=production rails assets:precompile"

# Set port to listen
EXPOSE 3000

# Define entrypoint
ENTRYPOINT nginx