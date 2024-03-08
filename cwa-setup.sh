#!/bin/bash
#https://github.com/ch604/cpanel-wildcard-autossl
#Distributed under BSD-3 license
#Setup script

version=0.1

#ensure we have the right environment
[ "$(ps h -p "$$" -o comm)" != "bash" ] && exec bash $0 $*
[ ! "$(whoami)" = "root" ] && echo "Need to run as root!" && exit 99
[ ! -f /etc/wwwacct.conf ] && echo "/etc/wwwacct.conf not found! Not a cpanel server?" && exit 99

###########
# FUNCTIONS
###########

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
	-x		uninstall this script, supporting scripts,
			all configured domains' renewal scripts,
			and any certificate files outside of
			cPanel's control (/etc/letsencrypt/*)
"
}

installs() {
}

################
# MAIN EXECUTION
################

if [ "$#" -lt "1" ]; then #no arguments passed
        helptext
        exit 1
fi

while getopts :ha:r:xu opt; do #parse arguments
	case $opt in
		h)	helptext
			exit 99
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
		\?)	echo -e "\n  Invalid option: -$OPTARG"
			helptext
			exit 2
			;;
		:)	echo -e "\n  Option -$OPTARG requires an argument"
			helptext
			exit 3
			;;
	esac
done

case $mode in
	add)	:
		;;
	remove)	:
		;;
	update)	:
		;;
	uninstall)	:
		;;
	*)	:
		;;
esac

#add mode, ensure we have the correct supporting software (acme.sh), ensure the domain has a wildcard subdomain set up, ensure that wildcard subdomain has a self-signed cert and add as needed, then ask for the cloudflare api token. write this to a secure file, then ask acme.sh to order the certificate. pull that cert from wherever it goes and add into whm via whmapi. write a post hook for the domain, and a cron job to automatically check the cert nightly.

#remove mode, remove any files we may have possibly created in relation to the given domain (credentials, post hook, cron job)

#update mode, find any files we could have created for all cpanel accounts, check their versions against the ones available on github, and then update each file as needed. verify functionality and revert if problems. update acme.sh.

#uninstall mode, list out all possible files that we could have created and all possible rpms we could have installed and remove them. print out which domains were set up at this point in time, and when their certs are due to expire. uninstall acme.sh.

#TODO handle domains removed from cpanel at crontime
#TODO handle removed api tokens

#exit codes:
# 0	success
# 99	bad environment, or -h passed
# 2	invalid option passed
# 3	no domain name passed
