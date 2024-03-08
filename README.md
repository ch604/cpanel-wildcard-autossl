# cpanel-wildcard-autossl
A certbot extension which automatically renews and installs wildcard certificates with DNS-01 verification from Cloudflare on cPanel servers. If you have:
* cPanel/WHM
* Wildcard Subdomains
* CloudFlare

... and you want free auto-renewing SSLs, then this script is for you!

## What is it?
cPanel helpfully will order SSLs for you through Let's Encrypt for all of your hosted sites if you so choose, however with wildcard subdomains, it REQUIRES control of DNS in order to perform validation. Many times, clients will wish to use CloudFlare as their DNS provider, but still want wildcard SSLs installed.

Let's Encrypt has no problem ordering this certificate with a CloudFlare API Token, but we must do it outside of cPanel and then import the ordered certificate. This script sets up all of that jazz for you, and will monitor the certificate for automatic renewal.

## How do I use it?
* Set up your domain and then your wildcard subdomain inside of cPanel.
* Set up your DNS in CloudFlare, and make it authoritative.
* Get an API Token for your zone from CloudFlare. Use the "Edit zone DNS" template, and scope the control to the single domain in question, and optionally scope the Client IP to the public IP of your cPanel server. Save this token somewhere safe for the time being.
* Download the setup script:

```
wget -q https://raw.githubusercontent.com/ch604/cpanel-wildcard-autossl/main/cwa-setup.sh -O /root/cwa-setup.sh

bash /root/cwa-setup.sh -h

bash /root/cwa-setup.sh -a domain.tld
```

* When the script requests your CloudFlare API Token, supply the one you made earlier.

When all said and done, the script will make a cronjob and post-hook for each domain you add so that ordered certificates can be set up again when they expire automatically. Using individual hooks and crons also lets you remove domains from this scheme if needed.

## FAQ
* Do I have to use Let's Encrypt as my SSL provider for all domains?

Nope! This mechanism works entirely outside of the cPanel AutoSSL structure, and imports the ordered certificate through the API. You don't even have to have AutoSSL enabled to set up your wildcard subdomain SSL.

* I'm having a problem!
Please file a bug report.
