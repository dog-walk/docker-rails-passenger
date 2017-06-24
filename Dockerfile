# Set initial image
FROM kozhin/rails:latest

# Set maintainer and image indo
MAINTAINER Konstantin Kozhin <konstantin@profitco.ru>
LABEL Description="This image runs Ruby on Rails server for production" Vendor="ProfitCo" Version="1.0"

# Install packages
RUN apt-get update && apt-get install libcurl4-openssl-dev libpcre3 libpcre3-dev unzip -y && apt-get clean all

# Setup Environment
ENV RAILS_ENV=production \
    SRC_PATH=/src \
    NPS_VERSION=1.12.34.2 \
    NGINX_VERSION=1.13.1

# Use SRC_PATH as a working dir
WORKDIR $SRC_PATH

# Download and install Google PageSpeed module for Nginx
RUN wget https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}-beta.zip \
    && unzip v${NPS_VERSION}-beta.zip \
    && rm v${NPS_VERSION}-beta.zip \
    && cd ngx_pagespeed-${NPS_VERSION}-beta/ \
    && PSOL_URL=https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz \
    && [ -e scripts/format_binary_url.sh ] && PSOL_URL=$(scripts/format_binary_url.sh PSOL_BINARY_URL) \
    && wget ${PSOL_URL} \
    && tar -xzvf $(basename ${PSOL_URL})

# Download and install Nginx web-server
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xzf nginx-${NGINX_VERSION}.tar.gz && \
    rm nginx-${NGINX_VERSION}.tar.gz

# Install Passenger
RUN bash -c 'source ~/.bash_profile \
    && gem install passenger --no-rdoc --no-ri'

# Build Nginx with modules
RUN bash -c 'source ~/.bash_profile \
    && passenger-install-nginx-module --auto \
        --nginx-source-dir=${SRC_PATH}/nginx-${NGINX_VERSION} \
        --extra-configure-flags=" \
        --with-file-aio \
        --with-http_addition_module \
        --with-http_auth_request_module \
        --with-http_dav_module \
        --with-http_flv_module \
        --with-http_gunzip_module \
        --with-http_gzip_static_module \
        --with-http_mp4_module \
        --with-http_random_index_module \
        --with-http_realip_module \
        --with-http_secure_link_module \
        --with-http_slice_module \
        --with-http_ssl_module \
        --with-http_stub_status_module \
        --with-http_sub_module \
        --with-http_v2_module \
        --with-ipv6 \
        --with-mail \
        --with-mail_ssl_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-threads \
        --with-cc-opt=\"-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2\" \
        --with-ld-opt=\"-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed\" \
        --add-module=${SRC_PATH}/ngx_pagespeed-${NPS_VERSION}-beta" \
    && ln -s /opt/nginx/sbin/nginx /usr/sbin/nginx \
    && rm -Rf $SRC_PATH/* \
    && chmod +x /root'

# Copy configuration files for Nginx
COPY nginx.conf /opt/nginx/conf/
COPY passenger.conf /opt/nginx/conf/
COPY application.conf /opt/nginx/conf/
COPY setup.sh /

# Update Nginx conf accordingly software installed
RUN bash -c 'source ~/.bash_profile \
    && chmod +x /setup.sh \
    && /setup.sh'

# Create and set application folder
RUN mkdir -p /app
WORKDIR /app

# Copy application inside container
ONBUILD COPY . /app/

# Update bash and install Rails application gems
ONBUILD RUN bash -c 'source ~/.bash_profile \
&& bundle install \
&& rails assets:precompile'

# Create secret key for the application
ONBUILD RUN bash -c 'source ~/.bash_profile \
&& echo Generating secret key... \
&& echo "env SECRET_KEY_BASE=$(bundle exec rake secret);" > /opt/nginx/conf/secret.key \
&& echo Done'

# Send request and error logs to docker log collector
RUN ln -sf /dev/stdout /opt/nginx/logs/access.log \
    && ln -sf /dev/stderr /opt/nginx/logs/error.log

# Set port to listen
EXPOSE 80 443

# Stop signal for container
STOPSIGNAL SIGTERM

# Define entrypoint for container
CMD ["nginx", "-g", "daemon off;"]
