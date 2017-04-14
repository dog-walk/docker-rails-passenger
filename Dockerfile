# Set initial image
FROM kozhin/rails:latest

# Set maintainer and image indo
MAINTAINER Konstantin Kozhin <konstantin@profitco.ru>
LABEL Description="This image runs Ruby on Rails server for production" Vendor="ProfitCo" Version="1.0"

# Setup Environment
ENV RAILS_ENV=production \
    SRC_PATH=/src \
    NPS_VERSION=1.11.33.5 \
    NGINX_VERSION=1.12.0

# Use SRC_PATH as a working dir
WORKDIR $SRC_PATH

# Download and install Google PageSpeed module for Nginx
RUN wget https://github.com/pagespeed/ngx_pagespeed/archive/release-${NPS_VERSION}-stable.zip && \
    unzip release-${NPS_VERSION}-stable.zip && \
    rm release-${NPS_VERSION}-stable.zip && \
    cd ngx_pagespeed-release-${NPS_VERSION}-beta/ && \
    wget https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz && \
    tar -xzf ${NPS_VERSION}.tar.gz && \
    rm ${NPS_VERSION}.tar.gz

# Download and install Nginx web-server
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz && \
    rm nginx-${NGINX_VERSION}.tar.gz

# Install Passenger
RUN bash -c 'source ~/.bash_profile \
&& gem install passenger --no-rdoc --no-ri \
&& passenger-install-nginx-module --auto \
    --nginx-source-dir=${SRC_PATH}/nginx-${NGINX_VERSION} \
    --extra-configure-flags=\"\
    --with-file-aio --with-http_addition_module \
    --with-http_auth_request_module --with-http_dav_module \
    --with-http_flv_module --with-http_gunzip_module \
    --with-http_gzip_static_module --with-http_mp4_module \
    --with-http_random_index_module --with-http_realip_module \
    --with-http_secure_link_module --with-http_slice_module \
    --with-http_ssl_module --with-http_stub_status_module \
    --with-http_sub_module --with-http_v2_module --with-ipv6 --with-mail \
    --with-mail_ssl_module --with-stream --with-stream_ssl_module \
    --with-threads --with-cc-opt='-g -O2 -fstack-protector \
    --param=ssp-buffer-size=4 -Wformat -Werror=format-security \
    -Wp,-D_FORTIFY_SOURCE=2' --with-ld-opt='-Wl,-Bsymbolic-functions \
    -Wl,-z,relro -Wl,--as-needed' \
    --add-module=${SRC_PATH}/ngx_pagespeed-release-${NPS_VERSION}-beta\" \
&& ln -s /opt/nginx/sbin/nginx /usr/sbin/nginx'

# Copy configuration files for Nginx
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
&& rails db:migrate \
&& rails assets:precompile'

# Create secret key for the application
ONBUILD RUN bash -c 'source ~/.bash_profile \
&& echo Generating secret key... \
&& echo "env SECRET_KEY_BASE=$(bundle exec rake secret);" > /opt/nginx/conf/secret.key \
&& echo Done'

# Set port to listen
EXPOSE 80 443

# Define entrypoint
ENTRYPOINT nginx
