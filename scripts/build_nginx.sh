#!/bin/bash
#
# Run with:
# $ heroku config:set AWS_S3_BUCKET=public-bucket
# $ heroku run 'curl https://gist.github.com/ejholmes/7120501/raw/build_nginx.sh | sh'

NGINX_VERSION=1.5.2
PCRE_VERSION=8.21

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=http://garr.dl.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2

echo "Downloading $nginx_tarball_url"
curl $nginx_tarball_url | tar xzf -

cd nginx-${NGINX_VERSION}

echo "Downloading $pcre_tarball_url"
curl $pcre_tarball_url | tar xjf -

./configure --with-http_realip_module --with-http_ssl_module --with-http_gzip_static_module --with-pcre=pcre-${PCRE_VERSION} --prefix=$HOME && make install

cd $HOME/sbin

curl \
-F "key=nginx" \
-F "acl=public-read" \
-F "Content-Type=application/octet-stream" \
-F "file=@nginx" \
http://${AWS_S3_BUCKET}.s3.amazonaws.com
