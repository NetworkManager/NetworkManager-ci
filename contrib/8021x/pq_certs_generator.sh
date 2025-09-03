#!/bin/bash

echo "=============================================="
echo "Complete ML-DSA-65 Certificate Generation"
echo "=============================================="
echo ""

# ==============================================
# DIRECTORY SETUP
# ==============================================

echo "=== STEP 1: Setting up directory structure ==="
echo ""

# Create directory structure (only if it doesn't exist)
if [ ! -d "certs" ]; then
    mkdir -p certs/server
    mkdir -p certs/client
    echo "Created directory structure:"
fi

echo "  certs/"
echo "    ├── server/"
echo "    └── client/"
echo ""

# ==============================================
# SERVER CERTIFICATE GENERATION
# ==============================================

echo "=== STEP 2: Generating Server Certificates ==="
echo ""

echo "Generating CA with ML-DSA-65..."
openssl genpkey -algorithm "ML-DSA-65" -out certs/server/hostapd_pq.ca.key.pem
openssl req -new -x509 -key certs/server/hostapd_pq.ca.key.pem -out certs/server/hostapd_pq.ca.pem -days 3650 \
    -subj "/C=US/ST=RedHat/L=Raleigh/O=WiFi-ML-DSA/CN=WiFi-ML-DSA-Root-CA"

echo "Generating server certificate with ML-DSA-65..."
openssl genpkey -algorithm "ML-DSA-65" -out certs/server/hostapd_pq.key.pem
openssl req -new -key certs/server/hostapd_pq.key.pem -out certs/server/hostapd_pq.csr \
    -subj "/C=US/ST=RedHat/L=Raleigh/O=WiFi-ML-DSA/CN=wifi-server.local"
openssl x509 -req -in certs/server/hostapd_pq.csr -CA certs/server/hostapd_pq.ca.pem -CAkey certs/server/hostapd_pq.ca.key.pem \
    -CAcreateserial -out certs/server/hostapd_pq.cert.pem -days 365

echo "Encrypting server private key with password 'redhat'..."
openssl pkey -in certs/server/hostapd_pq.key.pem -aes256 -out certs/server/hostapd_pq.key.enc.pem \
    -passout pass:redhat

echo "Generating DH parameters..."
openssl dhparam -out certs/server/hostapd_pq.dh.pem 3072

echo "✓ Server certificates generated in certs/server/"
echo ""

# ==============================================
# CLIENT CERTIFICATE GENERATION
# ==============================================

echo "=== STEP 3: Generating Client Certificates for User 'test' ==="
echo ""

# Copy CA certificate for client use
echo "Copying CA certificate for client..."
cp certs/server/hostapd_pq.ca.pem certs/client/test_user_pq.ca.pem

# Generate client private key with ML-DSA-65
echo "Generating client private key with ML-DSA-65..."
openssl genpkey -algorithm "ML-DSA-65" -out certs/client/test_user_pq.key.pem

# Generate client certificate request
echo "Generating client certificate request for user 'test'..."
openssl req -new -key certs/client/test_user_pq.key.pem -out certs/client/test_user_pq.csr \
    -subj "/C=US/ST=RedHat/L=Raleigh/O=WiFi-ML-DSA/CN=test"

# Sign client certificate with CA
echo "Signing client certificate with CA..."
openssl x509 -req -in certs/client/test_user_pq.csr -CA certs/server/hostapd_pq.ca.pem -CAkey certs/server/hostapd_pq.ca.key.pem \
    -CAcreateserial -out certs/client/test_user_pq.cert.pem -days 365

# Convert certificate to DER format
echo "Converting certificate to DER format..."
openssl x509 -in certs/client/test_user_pq.cert.pem -outform DER -out certs/client/test_user_pq.cert.der

# Encrypt private key with AES256 using password 'redhat'
echo "Encrypting private key with AES256 (password: redhat)..."
openssl pkey -in certs/client/test_user_pq.key.pem -aes256 -out certs/client/test_user_pq.key.enc.aes256.pem \
    -passout pass:redhat

# Create duplicate encrypted key file
echo "Creating additional encrypted key file..."
cp certs/client/test_user_pq.key.enc.aes256.pem certs/client/test_user_pq.key.enc.pem

# Create combined certificate and encrypted key file
echo "Creating combined certificate and encrypted key file..."
cat certs/client/test_user_pq.cert.pem certs/client/test_user_pq.key.enc.pem > certs/client/test_user_pq.cert_and_enc_key.pem

# Generate PKCS#12 bundle with password 'redhat'
echo "Generating PKCS#12 bundle..."
openssl pkcs12 -export -out certs/client/test_user_pq.p12 \
    -inkey certs/client/test_user_pq.key.pem \
    -in certs/client/test_user_pq.cert.pem \
    -certfile certs/client/test_user_pq.ca.pem \
    -name "test" \
    -passout pass:redhat

# Clean up temporary files
echo "Cleaning up temporary files..."
rm -f certs/server/hostapd_pq.csr certs/client/test_user_pq.csr

echo "✓ Client certificates generated in certs/client/"
echo ""

# ==============================================
# VERIFICATION AND SUMMARY
# ==============================================

echo "=== STEP 4: Verification ==="
echo ""

# Verify client certificate
echo "Verifying client certificate against CA..."
if openssl verify -CAfile certs/client/test_user_pq.ca.pem certs/client/test_user_pq.cert.pem; then
    echo "✓ Client certificate verification successful"
else
    echo "✗ Client certificate verification failed"
    exit 1
fi

# Display certificate subject
echo ""
echo "Certificate identity verification:"
echo -n "Username in certificate: "
openssl x509 -in certs/client/test_user_pq.cert.pem -noout -subject | sed 's/.*CN=\([^,]*\).*/\1/'

echo ""
echo "=============================================="
echo "GENERATION COMPLETE!"
echo "=============================================="
echo ""
echo "Directory structure created:"
echo "certs/"
echo "├── server/"
echo "│   ├── hostapd_pq.ca.pem                - CA certificate"
echo "│   ├── hostapd_pq.ca.key.pem            - CA private key"
echo "│   ├── hostapd_pq.cert.pem              - Server certificate"
echo "│   ├── hostapd_pq.key.pem               - Server private key (unencrypted)"
echo "│   ├── hostapd_pq.key.enc.pem           - Server private key (encrypted)"
echo "│   ├── hostapd_pq.dh.pem                - DH parameters"
echo "│   └── hostapd_pq.ca.srl                - CA serial number file"
echo "└── client/"
echo "    ├── test_user_pq.ca.pem              - CA certificate (copy)"
echo "    ├── test_user_pq.cert.pem            - Client certificate (PEM format)"
echo "    ├── test_user_pq.cert.der            - Client certificate (DER format)"
echo "    ├── test_user_pq.key.pem             - Private key (unencrypted)"
echo "    ├── test_user_pq.key.enc.pem         - Private key (AES256 encrypted)"
echo "    ├── test_user_pq.key.enc.aes256.pem  - Private key (AES256 encrypted)"
echo "    ├── test_user_pq.cert_and_enc_key.pem - Combined cert + encrypted key"
echo "    └── test_user_pq.p12                 - PKCS#12 bundle"
echo ""
echo "HOSTAPD CONFIGURATION PATHS:"
echo "  ca_cert=certs/server/hostapd_pq.ca.pem"
echo "  server_cert=certs/server/hostapd_pq.cert.pem"
echo "  private_key=certs/server/hostapd_pq.key.enc.pem"
echo "  private_key_passwd=redhat"
echo "  dh_file=certs/server/hostapd_pq.dh.pem"
echo ""
echo "CLIENT CERTIFICATE LOCATION:"
echo "  Certificate: certs/client/test_user_pq.p12"
echo "  Username: test"
echo "  Password: redhat"
echo ""
echo "Ready for hostapd EAP-TLS with ML-DSA-65 post-quantum security!"