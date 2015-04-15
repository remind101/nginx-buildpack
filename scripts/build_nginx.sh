#!/bin/bash
#
# Run with:
# $ heroku config:set AWS_S3_BUCKET=public-bucket
# $ heroku run 'curl https://gist.github.com/ejholmes/7120501/raw/build_nginx.sh | sh'

set -e

NGINX_VERSION=1.5.2
PCRE_VERSION=8.21
NGINX_ACCEPT_LANG_VERSION=2f69842
MAXMIND_VERSION=1.6.5

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=http://garr.dl.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2
nginx_accept_lang_tarball_url=https://github.com/giom/nginx_accept_language_module/tarball/${NGINX_ACCEPT_LANG_VERSION}
maxmind_tarball_url=https://github.com/maxmind/geoip-api-c/releases/download/v${MAXMIND_VERSION}/GeoIP-${MAXMIND_VERSION}.tar.gz

echo "Downloading $nginx_tarball_url"
curl $nginx_tarball_url | tar xzf -

cd nginx-${NGINX_VERSION}
BUILD_DIR=`pwd`

echo "Downloading $pcre_tarball_url"
curl $pcre_tarball_url | tar xjf -

echo "Downloading $nginx_accept_lang_tarball_url"
curl -L $nginx_accept_lang_tarball_url | tar xzf -

echo "Downloading $maxmind_tarball_url"
curl -L $maxmind_tarball_url | tar xzf -

echo "Building geoip.c"
cd GeoIP-${MAXMIND_VERSION}
./configure \
    --prefix=${BUILD_DIR}
make install
cd $BUILD_DIR

echo "Building nginx"
./configure \
  --with-cc-opt="-I ./include" \
  --with-ld-opt="-L ./lib" \
  --with-http_geoip_module \
  --with-http_realip_module \
  --with-http_ssl_module \
  --with-http_gzip_static_module \
  --with-pcre=pcre-${PCRE_VERSION} \
  --add-module=giom-nginx_accept_language_module-${NGINX_ACCEPT_LANG_VERSION} \
  --prefix=$HOME && make install

cd $HOME/sbin

curl \
-F "key=nginx" \
-F "acl=public-read" \
-F "Content-Type=application/octet-stream" \
-F "file=@nginx" \
http://${AWS_S3_BUCKET}.s3.amazonaws.com
