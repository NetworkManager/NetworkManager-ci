#!/bin/sh
#
# Run this script to setup a test CA, generate certificate
# and key pairs for server and client. Used for openconnect
# tests.

set -eu

command -v openssl >/dev/null 2>&1 || { echo >&2 "Unable to find openssl. Please make sure openssl is installed and in your path."; exit 1; }
command -v certtool >/dev/null 2>&1 || { echo >&2 "Unable to find certtool. Please make sure certtool is installed and in your path."; exit 1; }

if [[ ! -f server.tmpl || ! -f client.tmpl || ! -f ca.tmpl ]]; then
    echo "Please run this script from the contrib/openconnect directory"
    exit 1
fi


# CA cert and key
certtool --generate-privkey --outfile ca-key.pem
certtool --generate-self-signed --load-privkey ca-key.pem \
  --template ca.tmpl --outfile ca-cert.pem

# Server cert and key
certtool --generate-privkey --outfile server-key.pem
certtool --generate-certificate --load-privkey server-key.pem \
  --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem \
  --template server.tmpl --outfile server-cert.pem

# Client cert and key
certtool --generate-privkey --outfile client-key.pem
certtool --generate-certificate --load-privkey client-key.pem \
  --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem \
  --template client.tmpl --outfile client-cert.pem

openssl rsa -aes256 -in client-key.pem -out client-key-enc.pem -passout pass:test-password
