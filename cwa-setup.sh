#!/bin/bash
#https://github.com/ch604/cpanel-wildcard-autossl
#Distributed under BSD-3 license
#Setup script

version=0.9

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
have DNS on CloudFlare. Certs pulled with acme.sh.

USAGE
Prepare yourself an API token from CloudFlare for the domain
in question which has zone.edit capabilities, then run this
script to set up that domain:

 bash cwa-setup.sh -a domain.tld

This will set up *.domain.tld on a cronjob.

	-h		display this help text
	-a domain.tld	set up *domain.tld for autorenew
	-r domain.tld	remove *domain.tld from autorenew
	-u		update all supporting software
	-x		uninstall this script, supporting scripts,
			all configured domains' renewal scripts,
			and any certificate files outside of
			cPanel's control (/etc/letsencrypt/*)
"
}

installs() {
	echo "Setting up supporting software..."
	# set up URI::Escape
	true | cpan -v &> /dev/null #make sure cpan defaults are stored
	/usr/local/cpanel/bin/cpanm URI::Escape &> /dev/null
	# set up python
	[ ! $(which python 2> /dev/null) ] && [ $(which python2 2> /dev/null) ] && ln -s $(which python2) /usr/bin/python
	[ ! $(which python 2> /dev/null) ] && [ $(which python3 2> /dev/null) ] && ln -s $(which python3) /usr/bin/python
	[ ! $(which python 2> /dev/null) ] && yum -y -q install python
	# set up acme.sh
	bash <(curl -s https://get.acme.sh/) &> /dev/null
	# make credential storage directory
	dir=/root/.cwa/cloudflare
	mkdir -p -m 700 $dir
	# if anything failed, die
	if ! cpan -l 2> /dev/null | grep -q ^URI\:\:Escape || [ ! $(which python 2> /dev/null) ] || [ ! -x /root/.acme.sh/acme.sh ] || [ ! -d $dir ]; then
		echo "Something failed to install!"
		echo "I need URI::Escape cpan module, python, acme.sh, and /root/.cwa/cloudflare directory."
		exit 4
	fi
}

domaincheck() {
	if ! grep -q ^*.${domain}: /etc/userdatadomains; then
		echo "This domain is not set up for wildcard hosting on this server!"
		echo "I checked /etc/userdatadomains for *.$domain."
		echo "Please fix this and try again."
		exit 6
	fi
}

store_cf_token() {
	echo "Please pass the CloudFlare API Token you created for $domain:"
	read -e token
	echo "Testing token..."
	output=$(mktemp)
	curl -s -X GET https://api.cloudflare.com/client/v4/zones -H "Authorization: Bearer $token" -H "Content-Type: application/json" > $output
	if cat $output | python -c 'import sys,json; tokens=json.load(sys.stdin); print (tokens["success"])' | grep -q -i True; then
		if [ $(cat $output | python -c 'import sys,json; tokens=json.load(sys.stdin); print len(tokens["result"])') -eq 1 ]; then
			touch $dir/$domain.ini
			chmod 400 $dir/$domain.ini
			echo 'CF_Token="'$token'"' > $dir/$domain.ini
			echo 'CF_Zone_ID="'$(cat $output | python -c 'import sys,json; tokens=json.load(sys.stdin); print (tokens["result"][0]["id"])')'"' >> $dir/$domain.ini
		else
			echo "There was a problem using the supplied token!"
			echo "This token controls more than one domain!"
			cat $output | python -c 'import sys,json; tokens=json.load(sys.stdin)
for token in tokens["result"] : print (token["name"])'
			echo "Please make a new token scoped to a single domain, and try again."
			\rm -f $output
			unset token output
			exit 5
		fi
	else
		echo "There was a problem using the supplied token!"
		cat $output | python -c 'import sys,json; tokens=json.load(sys.stdin); print (tokens["errors"])'
		echo "Please fix this error and try again."
		\rm -f $output
		unset token output
		exit 5
	fi
	\rm -f $output
	unset token output
}

write_renew_hook() {
	echo "Writing renewal hook..."
	cat > $dir/$domain.hook.sh << EOF
#!/bin/bash
#https://github.com/ch604/cpanel-wildcard-autossl
#post-renewal hook

/usr/local/cpanel/bin/whmapi1 installssl domain=*.$domain crt=\$(cat \$CERT_PATH | perl -MURI::Escape -ne 'print uri_escape(\$_)') key=\$(cat \$CERT_KEY_PATH | perl -MURI::Escape -ne 'print uri_escape(\$_)') cab=\$(cat \$CA_CERT_PATH | perl -MURI::Escape -ne 'print uri_escape(\$_)')
EOF
	chmod +x $dir/$domain.hook.sh
}

order_new_ssl() {
	echo "Ordering SSL for *.$domain."
	echo "This might take a minute or so..."
	source $dir/$domain.ini
	export CF_Token CF_Zone_ID
	/root/.acme.sh/acme.sh --issue --dns dns_cf -d "*.$domain" --server letsencrypt --renew-hook $dir/$domain.hook.sh &> /dev/null
	if [ $? -eq 0 ]; then
		echo "Order success! Forcibly renewing to install cert with whmapi..."
		/root/.acme.sh/acme.sh --renew --force -d "*.$domain" &> /dev/null
		echo "You should be all set from here on out."
	else
		echo "There was a problem running acme.sh!"
		echo "Please check the log files at /root/.acme.sh/acme.sh.log and try again."
		exit 10
	fi
}

remove_domain() {
	echo "Are you sure you want to remove $domain? This will only prevent the certificate from being renewed; its certificates will remain inside of cPanel. You will need a new CloudFlare API Token in order to set up the domain again."
	echo "Press enter to continue, or Ctrl-C to exit."
	read -s
	/root/.acme.sh/acme.sh --remove -d "*.$domain"
	[ -d /root/.acme.sh/\*.$domain ] && \rm -rf /root/.acme.sh/\*.$domain
	[ -d /root/.acme.sh/\*.$domain_ecc ] && \rm -rf /root/.acme.sh/\*.$domain_ecc
	\rm -f /root/.cwa/cloudflare/$domain.hook.sh
	\rm -f /root/.cwa/cloudflare/$domain.ini
	echo "All done! $domain has been removed from autorenewal."
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
			echo $domain | grep -q ^\*\. && domain=$(echo $domain | cut -d. -f2-)
			;;
		r)	mode=remove
			domain=$OPTARG
			echo $domain | grep -q ^\*\. && domain=$(echo $domain | cut -d. -f2-)
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
	add)	installs
		domaincheck
		store_cf_token
		write_renew_hook
		order_new_ssl
		;;
	remove)	installs
		domaincheck
		remove_domain
		;;
	update)	installs
		;;
	uninstall)	echo "This currently does not do anything."
		;;
	*)	:
		;;
esac

#exit codes:
# 0	success
# 2	invalid option passed
# 3	no domain name passed
# 4	installs failed
# 5	bad api token
# 6	missing cpanel subdomain
# 10	acme.sh failed
# 99	bad environment, or -h passed
