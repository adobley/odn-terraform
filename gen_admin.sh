#!/bin/bash

OUT_DIR=$PWD/out
CONFIG_DIR=$PWD/config
TEMPLATE_DIR=$PWD/template

TEMPLATE=$(cat $TEMPLATE_DIR/client.json | sed "s/\${SERVERNAME}/$1/g")

echo $TEMPLATE | cfssl gencert \
  -ca=$OUT_DIR/ca.pem \
  -ca-key=$OUT_DIR/ca-key.pem \
  -config=$CONFIG_DIR/ca-config.json \
  -profile=client - | \
  cfssljson -bare $OUT_DIR/admin