# cpanel-wildcard-autossl
A script which automatically renews and installs wildcard certificates with DNS-01 verification from Cloudflare on cPanel servers. If you have:
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

When all said and done, the script will have a cron and post-renewal-hook set up for you to install renewed certificates automatically.

## FAQ
* What's under the hood?

It's a bash script that you downloaded from the internet, so I recommend you read through it before you execute it. But in short, it installs [acme.sh](https://github.com/acmesh-official/acme.sh), verifies the environment is correct for the domain you passed to get a wildcard SSL installed, gets your API token, requests the certificate, and makes a renewal hook which will take those certificates and put them into the whmapi to properly install them. The installation of acme.sh will take care of automatic renewal for us, and the post-renewal-hook is persistent.

* Do I have to use Let's Encrypt as my SSL provider for all domains?

Nope! This mechanism works entirely outside of the cPanel AutoSSL structure, and imports the ordered certificate through the API. You don't even have to have AutoSSL enabled to set up your wildcard subdomain SSL.

* Can you expand the script to do more stuff with acme.sh?

While it's possible to use alternate SSL or DNS providers, or non-wildcard domains, or manipulate key algos for advanced security, its outside the scope of this specific project. I just needed a way to get wildcard SSLs to stay up to date which was simple to use. Feel free to fork the project or submit patch requests!

If you want to set up acme.sh on your own, and just use the 'import a certificate to cPanel' part, you can grab 'renew-hook.sh' and use that as your --renew-hook argument for acme.sh manually. Just make sure you have URI::Escape installed through cpan. acme.sh handles the cronjob for certificates it orders.

* I'm having a problem! Where can I get help?

Please file a bug report :)
