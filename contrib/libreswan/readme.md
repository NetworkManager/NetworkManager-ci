# Certificates #

## Init ##

Initialize openssl in `./ca` directory, reset internal certificate database of openssl. Do this even if some certificates already generated, because openssl does not allow to generate certificate with the same common name twice.

```bash
cd ca/
mkdir newcerts
echo 01 > serial
echo -n > index.txt
cd ..
```

## Generate CSR ##

Check `.conf` files in `./server` and `./client` directories (modify CommonName / IP / DNS if needed).

**Warning:** *Following commands will overwrite existing `.key` files!*


```bash
cd server/
openssl req -new -out libreswan_server.csr -config libreswan_server.conf
cd ../client/
openssl req -new -out libreswan_client.csr -config libreswan_client.conf
cd ..
```

## Generate certificates from CSR ##

This step requires password, if CA private key is encrypted.

```bash
cd ca/
openssl ca -in ../server/libreswan_server.csr -out ../server/libreswan_server.cert.pem -config libreswan_ca.conf
openssl ca -in ../client/libreswan_client.csr -out ../client/libreswan_client.cert.pem -config libreswan_ca.conf
cd ..
```

## Pack in PKCS12 ##

Options `-name` and `-caname` are important, they are used by `certutil` when importing into NSS database. Password can be left empty if prompted.

```bash
cd server/
openssl pkcs12 -export -in libreswan_server.cert.pem -inkey libreswan_server.key.pem -certfile ../ca/libreswan_ca.cert.pem -out libreswan_server.p12 -name LibreswanServer -caname RedHat
cd ../client/
openssl pkcs12 -export -in libreswan_client.cert.pem -inkey libreswan_client.key.pem -certfile ../ca/libreswan_ca.cert.pem -out libreswan_client.p12 -name LibreswanClient -caname RedHat
cd ..
```

## Clean old configuration

If you have machine that have old configuration be sure to clean up files in the following dirs (if exist), otherwise prepare fails with certificate serial error:

```bash
rm -f /opt/ipsec/nss/*
rm -f /var/lib/ipsec/nss/*
rm -f /etc/ipsec.d/nss/*
```

## Generate new self-signed CA certificate and key

Do this, if you do not know private key password or CA certificate is expired.

Check company information in `./libreswan_ca.req.conf`.

You need to enter new private key password twice. Remember the password, it is required to sign the certificates.

### Disable CA private key password ###

If you do not want to encrypt private key of CA (do not publish such private key anywhere), then change `encrypt_key` to `no` in `[ req ]` section in `ca/libreswan_ca.req.conf`.

```bash
cd ca/
openssl req -x509 -config libreswan_ca.req.conf -out libreswan_ca.cert.pem -days 3650
cd ..
```
