#!/bin/bash
#https://github.com/ch604/cpanel-wildcard-autossl
#Distributed under BSD-3 license
#Post-update hook script, run after successful SSL renewal

version=0.1

domain="*.[[REPLACE]]"

#ensure URI::Escape is up to date
/usr/local/cpanel/bin/cpanm URI::Escape &> /dev/null

#check for $domain's new ssl file, if all necessary files exist, then install through whmapi1
# /usr/local/cpanel/bin/whmapi1 installssl domain=${domain} crt=$(cat ${certfile} | perl -MURI::Escape -ne 'print uri_escape($_)') key=$(cat ${keyfile} | perl -MURI::Escape -ne 'print uri_escape($_)') cab=$(cat ${cabundle} | perl -MURI::Escape -ne 'print uri_escape($_)')
