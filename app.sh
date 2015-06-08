LDFLAGS="-L${DEPS}/lib"

### ZLIB ###
_build_zlib() {
# Closest to the one that ships with the 5N (v1.2.3.4)
local VERSION="1.2.3"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://downloads.sourceforge.net/project/libpng/zlib/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --shared
make
make install
popd
}

### OPENSSL ###
_build_openssl() {
# Same as the one that ships with the 5N
local VERSION="0.9.8n"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="https://www.openssl.org/source/old/0.9.x/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./Configure --prefix="${DEPS}" shared threads linux-generic32 \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  -DL_ENDIAN ${CFLAGS} ${LDFLAGS}
sed -e "s/-O3//g" -i Makefile
make -j1
make install_sw
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
./configure --host="${HOST}" --prefix="" --localedir="/usr/share/locale" \
  --with-ssl=openssl --with-openssl=yes --with-libssl-prefix="${DEPS}" --disable-pcre --disable-rpath
make
make install DESTDIR="${DEST}"
"${STRIP}" -s -R .comment -R .note -R .note.ABI-tag "${DEST}/bin/wget"
echo "ca_certificate = /etc/cacert.pem" >> "${DEST}/etc/wgetrc"
popd
}

### CERTIFICATES ###
_build_certificates() {
wget -O "${DEST}/etc/cacert.pem" "http://curl.haxx.se/ca/cacert.pem"
}

_build() {
  _build_zlib
  _build_openssl
  _build_wget
  _build_certificates
  _package
}
