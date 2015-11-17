CFLAGS="${CFLAGS:-} -ffunction-sections -fdata-sections"
LDFLAGS="${LDFLAGS:-} -L${DEPS}/lib -Wl,--gc-sections"

### ZLIB ###
_build_zlib() {
# Closest to the one that ships with the 5N (v1.2.3.4)
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://downloads.sourceforge.net/project/libpng/zlib/${VERSION}/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --static
make
make install
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2d"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="/" --openssldir="/etc/ssl" \
  zlib --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  no-shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw INSTALL_PREFIX="${DEPS}"
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
PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="" --localedir="/usr/share/locale" \
  --with-ssl=openssl --with-openssl=yes --with-libssl-prefix="${DEPS}" --disable-pcre --disable-rpath
make
make install DESTDIR="${DEST}"
"${STRIP}" -s -R .comment -R .note -R .note.ABI-tag "${DEST}/bin/wget"
echo "ca_certificate = /etc/cacert.crt" >> "${DEST}/etc/wgetrc"
popd
}

### CERTIFICATES ###
_build_certificates() {
# update CA certificates on a Debian/Ubuntu machine:
#sudo update-ca-certificates
cp -vf /etc/ssl/certs/ca-certificates.crt "${DEST}/etc/cacert.crt"
}

_build() {
  _build_zlib
  _build_openssl
  _build_wget
  _build_certificates
  _package
}
