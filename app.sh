### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib"
make
make install
rm -v "${DEST}/lib/libz.a"
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2a"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.openssl.org/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 < "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" shared threads linux-armv4 no-asm --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include"--with-zlib-lib="${DEST}/lib" \
  -DL_ENDIAN ${CFLAGS} ${LDFLAGS}
sed -i -e "s/-O3//g" Makefile
make -j1
make install_sw
cp -avR "${DEPS}/lib"/* "${DEST}/lib/"
rm -vfr "${DEPS}/lib"
rm -vf "${DEST}/lib/libcrypto.a" "${DEST}/lib/libssl.a"
sed -i -e "s|^exec_prefix=.*|exec_prefix=${DEST}|g" "${DEST}/lib/pkgconfig/openssl.pc"
popd
}

### WGET ###
_build_wget() {
local VERSION="1.16.3"
local FOLDER="wget-${VERSION}"
local FILE="${FOLDER}.tar.xz"
local URL="http://ftp.gnu.org/gnu/wget/${FILE}"

_download_xz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" ./configure --host="${HOST}" --prefix="${DEST}" --mandir="${DEST}/man"  --with-ssl=openssl --with-openssl=yes --with-libssl-prefix="${DEST}" --disable-pcre
make
make install
echo "ca_certificate = ${DEST}/etc/ssl/certs/ca-certificates.crt" >> "${DEST}/etc/wgetrc"
mv -f "${DEST}/etc/wgetrc" "${DEST}/etc/wgetrc.default"
popd
}

### CERTIFICATES ###
_build_certificates() {
# update CA certificates on a Debian/Ubuntu machine:
#sudo update-ca-certificates
#cp -vf /etc/ssl/certs/ca-certificates.crt "${DEST}/etc/ssl/certs/"
wget -O "${DEST}/etc/ssl/certs/ca-certificates.crt" "http://curl.haxx.se/ca/cacert.pem"
}

_build() {
  _build_zlib
  _build_openssl
  _build_wget
  _build_certificates
  _package
}
