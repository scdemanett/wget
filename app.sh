CFLAGS="${CFLAGS:-} -ffunction-sections -fdata-sections"
LDFLAGS="${LDFLAGS:-} -L${DEPS}/lib -Wl,--gc-sections"

### ZLIB ###
_build_zlib() {
local VERSION="1.2.11"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib" --shared
make
make install
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.1.1g"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://www.openssl.org/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
cp -vfa "${DEPS}/lib/libssl.so"* "${DEST}/lib/"
cp -vfa "${DEPS}/lib/libcrypto.so"* "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/engines"* "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/pkgconfig" "${DEST}/lib/"
rm -vf "${DEPS}/lib/libcrypto.a" "${DEPS}/lib/libssl.a"
popd
}

### WGET ###
_build_wget() {
local VERSION="1.20.3"
local FOLDER="wget-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://ftp.gnu.org/gnu/wget/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
PKG_CONFIG_PATH="${DEST}/lib/pkgconfig" \
  ./configure --host="${HOST}" --prefix="${DEST}" --mandir="${DEST}/man" \
  --with-ssl=openssl --with-openssl=yes --with-libssl-prefix="${DEST}" \
  --disable-pcre
make
make install
echo "ca_certificate = ${DEST}/etc/ssl/certs/ca-certificates.crt" >> "${DEST}/etc/wgetrc"
mv -f "${DEST}/etc/wgetrc" "${DEST}/etc/wgetrc.default"
"${STRIP}" -s -R .comment -R .note -R .note.ABI-tag "${DEST}/bin/wget"
popd
}

### CERTIFICATES ###
_build_certificates() {
# update CA certificates on a Debian/Ubuntu machine:
#sudo update-ca-certificates
cp -vf /etc/ssl/certs/ca-certificates.crt "${DEST}/etc/ssl/certs/"
}

_build() {
  _build_zlib
  _build_openssl
  _build_wget
  _build_certificates
  _package
}
