# Set initial image
FROM kozhin/rails:latest

# Set maintainer and image indo
MAINTAINER Konstantin Kozhin <konstantin@profitco.ru>
LABEL Description="This image runs Ruby on Rails server for production" Vendor="ProfitCo" Version="1.0"

# Install required packages
RUN apt-get update && apt-get install libcurl4-openssl-dev -y && apt-get clean all

# Setup Environment
ENV NODE_ENV production
ENV RAILS_ENV production
ENV SRC_PATH /src
ENV NGINX_VERSION 1.13.6
ENV NGINX_PATH /opt/nginx

# Set working directory for SRC_PATH (create if none)
WORKDIR $SRC_PATH

# Download Nginx
RUN wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz \
    && tar -xzf nginx-${NGINX_VERSION}.tar.gz \
    && rm nginx-${NGINX_VERSION}.tar.gz

# Install Passenger gem
RUN bash -c 'source ~/.bash_profile \
    && gem install passenger --no-rdoc --no-ri'

# Build Nginx with Passenger module
RUN bash -c 'source ~/.bash_profile \
    && passenger-install-nginx-module --auto \
        --prefix=${NGINX_PATH} \
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
        --with-threads" \
    && ln -s $NGINX_PATH/sbin/nginx /usr/sbin/nginx \
    && ln -s $NGINX_PATH /etc/nginx \
    && rm -Rf $SRC_PATH/* \
    && chmod o+x /root'

# Set new working dir
WORKDIR $NGINX_PATH

# Copy configuration files for Nginx
COPY nginx.conf ./conf/
COPY passenger.conf ./conf/
COPY application.conf ./conf/
COPY setup.sh /

# Update Nginx conf accordingly software installed
RUN bash -c 'source ~/.bash_profile \
    && chmod +x /setup.sh \
    && /setup.sh'

# Create and set application folder
RUN mkdir -p /app
WORKDIR /app

# Send request and error logs to docker log collector
RUN ln -sf /dev/stdout $NGINX_PATH/logs/access.log \
    && ln -sf /dev/stderr $NGINX_PATH/logs/error.log

# Set ports to listen
EXPOSE 80 443

# Stop signal for container
STOPSIGNAL SIGTERM

# Define entrypoint for container
ENTRYPOINT ["nginx", "-g", "daemon off;"]
