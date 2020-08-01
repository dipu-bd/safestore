#!/usr/bin/env bash
ALIAS := "safestore"
PASSWORD := "d15af3st0r3pu"

ifeq ($(OS),Windows_NT)
HOME := $(shell echo %USERPROFILE%)
RMDIR := rd /S /Q
MKDIR := mkdir
COPY := copy
DELETE := del
KEYSTORE := "android\app\.keystore"
else
HOME := $(shell cd ~ && pwd)
RMDIR := rm -rf
MKDIR := mkdir -p
COPY := cp
DELETE := rm -f
KEYSTORE := "android/app/.keystore"
endif

debug-key :: # To get the debug certificate fingerprint:
	@keytool -list -v \
		-alias androiddebugkey \
		-storepass android \
		-keypass android \
		-keystore $(HOME)/.android/debug.keystore

release-key :: # To get the release certificate fingerprint
	@keytool -list -v \
		-alias $(ALIAS) \
		-storepass $(PASSWORD) \
		-keypass $(PASSWORD) \
		-keystore $(KEYSTORE)

export-key :: # To export the certificate for the upload key to PEM format
	@keytool -export -rfc \
		-file upload_certificate.pem \
		-alias $(ALIAS) \
		-storepass $(PASSWORD) \
		-keypass $(PASSWORD) \
		-keystore $(KEYSTORE)

generate-key :: # To generate new key-pair
	@$(DELETE) $(KEYSTORE) || echo -
	@keytool -genkeypair \
		-keyalg RSA \
		-keysize 2048 \
		-validity 36500 \
		-storetype PKCS12 \
		-alias $(ALIAS) \
		-storepass $(PASSWORD) \
		-keypass $(PASSWORD) \
		-keystore $(KEYSTORE) \
		-dname "CN=Admin, OU=Safestore, O=Bitanon, L=Dhaka, S=Dhaka, C=BD"
