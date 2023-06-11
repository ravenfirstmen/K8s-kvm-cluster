#!/bin/bash

# Geração os certificados para o cluster e seguir as regras com os SAN correctos
# Isto porque o nginx não gosta muito de não os ter.... :-
CA_FILE_NAME_PREFIX="public-ca"

if [ ! -f "$CA_FILE_NAME_PREFIX-crt.pem" ];
then
    openssl genrsa -out $CA_FILE_NAME_PREFIX-key.pem 4096
    openssl req -x509 -new -nodes -key $CA_FILE_NAME_PREFIX-key.pem -sha256 -days 1826 -out $CA_FILE_NAME_PREFIX-crt.pem -subj '/CN=ca.k8s.local/C=PT/ST=Braga/L=Famalicao/O=Casa/OU=Escritorio'
    # instalar no sistema
    sudo cp $CA_FILE_NAME_PREFIX-crt.pem /usr/local/share/ca-certificates/$CA_FILE_NAME_PREFIX-crt.crt
    sudo update-ca-certificates

    rm -rf *.pem
fi

ALL_DOMAINS=(lb mattermost)

for DOMAIN in ${ALL_DOMAINS[@]}; do

    if [ ! -f "$DOMAIN-crt.pem" ];
    then

        openssl genrsa -out $DOMAIN-key.pem 4096
        openssl req -new -key $DOMAIN-key.pem -out $DOMAIN.csr -subj "/CN=$DOMAIN.k8s.local/C=PT/ST=Braga/L=Famalicao/O=Casa/OU=Escritorio"

cat > tmp.ext << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $DOMAIN
DNS.2 = $DOMAIN.k8s.local
IP.1 = 127.0.0.1
EOF

        openssl x509 -req -in $DOMAIN.csr -CA $CA_FILE_NAME_PREFIX-crt.pem -CAkey $CA_FILE_NAME_PREFIX-key.pem -CAcreateserial -out $DOMAIN-crt.pem -days 825 -sha256 -subj "/CN=$DOMAIN.k8s.local/C=PT/ST=Braga/L=Famalicao/O=Casa/OU=Escritorio" -extfile tmp.ext
    fi

done
rm -rf tmp.ext
rm -rf *.csr
