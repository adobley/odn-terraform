#!/bin/bash

CONFIG_DIR=$PWD/config
OUT_DIR=$PWD/out

cfssl gencert -initca $CONFIG_DIR/ca-csr.json | cfssljson -bare $OUT_DIR/ca -