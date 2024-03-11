#!/bin/bash
#https://github.com/ch604/cpanel-wildcard-autossl
#post-renewal hook for acme.sh to install ssl in cPanel
#depends on presence of exported variables from acme.sh
#use: `acme.sh .... --renew-hook /path/to/renew-hook.sh`

/usr/local/cpanel/bin/whmapi1 installssl domain=$Le_Domain crt=$(cat $CERT_PATH | perl -MURI::Escape -ne 'print uri_escape($_)') key=$(cat $CERT_KEY_PATH | perl -MURI::Escape -ne 'print uri_escape($_)') cab=$(cat $CA_CERT_PATH | perl -MURI::Escape -ne 'print uri_escape($_)')
