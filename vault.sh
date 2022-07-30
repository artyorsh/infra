#!/usr/bin/env bash

ACCOUNT_NAME=$(whoami)
LABEL="ansible-vault-password"

/usr/bin/security find-generic-password -a "$ACCOUNT_NAME" -l "$LABEL" -w