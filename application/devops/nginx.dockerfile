# 使用 Nginx 官方镜像作为基础镜像
FROM nginx:1.21.1-alpine

# 安装必要的工具和依赖
RUN apk add --no-cache \
    gcc \
    libc-dev \
    make \
    pcre-dev \
    zlib-dev \
    linux-headers \
    curl \
    unzip

# 下载并解压  Header more nginx 模块
RUN curl -sSL https://github.com/openresty/headers-more-nginx-module/archive/refs/heads/master.zip -o /tmp/headers.zip && \
    unzip /tmp/headers.zip -d /tmp && \
    mv /tmp/headers-more-nginx-module-master /tmp/headers-more-nginx-module

# 下载并解压 Echo Nginx 模块
RUN curl -sSL https://github.com/openresty/echo-nginx-module/archive/refs/heads/master.zip -o /tmp/echo.zip && \
    unzip /tmp/echo.zip -d /tmp && \
    mv /tmp/echo-nginx-module-master /tmp/echo-nginx-module

# 下载并解压 Nginx 源码
RUN NGINX_VERSION=$(nginx -v 2>&1 | awk -F/ '{print $2}') && \
    curl -sSL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o /tmp/nginx.tar.gz && \
    tar -zxC /tmp -f /tmp/nginx.tar.gz

# 编译 Nginx 并添加 more headers 和 Echo 模块
RUN cd /tmp/nginx-${NGINX_VERSION} && \
    ./configure --with-compat --user=www-data --group=www-data --add-dynamic-module=/tmp/headers-more-nginx-module --add-dynamic-module=/tmp/echo-nginx-module && \
    make modules && \
    cp objs/ngx_http_headers_more_filter_module.so /etc/nginx/modules && \
    cp objs/ngx_http_echo_module.so /etc/nginx/modules

# 清理不需要的文件
RUN apk del gcc libc-dev make linux-headers curl unzip && \
    rm -rf /tmp/* && \
    rm -rf /etc/nginx/conf.d/*

# 将模块加载配置写入临时文件并追加原始配置文件内容
RUN echo "load_module modules/ngx_http_headers_more_filter_module.so;" > /tmp/temp_conf && \
    echo "load_module modules/ngx_http_echo_module.so;" >> /tmp/temp_conf && \
    cat /etc/nginx/nginx.conf >> /tmp/temp_conf && \
    mv /tmp/temp_conf /etc/nginx/nginx.conf

# 设置 stub
COPY ./nginx/default.conf /etc/nginx/conf.d/default.conf

# 设置工作目录和端口
WORKDIR /etc/nginx
EXPOSE 80
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]