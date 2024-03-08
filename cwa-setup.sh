#!/bin/bash
#https://github.com/ch604/cpanel-wildcard-autossl
#Distributed under BSD-3 license
#Setup script

version=0.1

#ensure we are using bash
[ "$(ps h -p "$$" -o comm)" != "bash" ] && exec bash $0 $*

helptext() {
	echo "
cPanel Wildcard AutoSSL Setup Script
Version $version

Set up your cPanel server to automatically install and renew
Let's Encrypt certificates for wildcard subdomains which
have DNS on CloudFlare.

USAGE
Prepare yourself an API token from CloudFlare for the domain
in question which has zone.edit capabilities, then run this
script to set up that domain:

 bash cwa-setup.sh -a domain.tld

This will set up *.domain.tld on a cronjob.

	-h		display this help text
	-a domain.tld	set up domain.tld for autorenew
	-r domain.tld	remove domain.tld from autorenew
	-u		update all crons and hooks to the
			latest version on github
	-x		uninstall this script, supporting RPMs,
			all configured domains' renewal scripts,
			and any certificate files outside of
			cPanel's control (/etc/letsencrypt/*)
"
}

if [ "$#" -lt "1" ]; then #no arguments passed
        helptext
        exit
fi

while getopts :ha:r:xu opt; do #parse arguments
	case $opt in
		h)	helptext
			exit
			;;
		x)	mode=uninstall
			;;
		u)	mode=update
			;;
		a)	mode=add
			domain=$OPTARG
			;;
		r)	mode=remove
			domain=$OPTARG
			;;
		\?)	echo "  Invalid option: -$OPTARG"
			helptext
			exit
			;;
		:)	echo "  Option -$OPTARG requires an argument"
			helptext
			exit
			;;
	esac
done

#uninstall mode, list out all possible files that we could have created and all possible rpms we could have installed and remove them. print out which domains were set up at this point in time, and when their certs are due to expire. clean up the letsencrypt storage folder.

#add mode, ensure we have the correct rpms installed (based on our os version), ensure the domain has a wildcard subdomain set up, ensure that wildcard subdomain has a self-signed cert and add as needed, then ask for the cloudflare api token. write this to a secure file, then ask certbot to order the certificate. pull that cert from wherever it goes and add into whm via whmapi. write a post hook for the domain, and a cron job for the cpanel user to automatically check the cert nightly. ensure that certbot.timer is disabled in favor of our own cronjobs.

#remove mode, remove any files we may have possibly created in relation to the given domain (credentials, post hook, cron job)

#TODO handle domains removed from cpanel at crontime
