# Set initial image
FROM kozhin/rails:latest

# Set maintainer and image indo
MAINTAINER Konstantin Kozhin <konstantin@profitco.ru>
LABEL Description="This image runs Ruby on Rails server for production" Vendor="ProfitCo" Version="1.0"

# Install Google PageSpeed module for Nginx


# Install Passenger
RUN bash -c 'source ~/.bash_profile \
&& gem install passenger --no-rdoc --no-ri \
&& passenger-install-nginx-module --auto \
&& ln -s /opt/nginx/sbin/nginx /usr/sbin/nginx \
&& chmod 755 /root'

# Copy configuration files for nginx
COPY nginx.conf /opt/nginx/conf/
COPY passenger.conf /opt/nginx/conf/
COPY rails-application.conf /opt/nginx/conf/

# Create and set application folder
RUN mkdir -p /app
WORKDIR /app

# Copy application inside container
ONBUILD COPY . /app/

# Update bash and install Rails application gems
ONBUILD RUN bash -c 'source ~/.bash_profile \
&& bundle install \
&& RAILS_ENV=production rails db:migrate \
&& RAILS_ENV=production rails assets:precompile'

# Create secret key for the application
ONBUILD RUN bash -c 'source ~/.bash_profile \
&& echo Generating secret key... \
&& echo "env SECRET_KEY_BASE=$(bundle exec rake secret);" > /opt/nginx/conf/secret.key \
&& echo Done'

# Set port to listen
EXPOSE 80 443

# Define entrypoint
ENTRYPOINT nginx
