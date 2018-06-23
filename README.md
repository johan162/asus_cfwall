# README asus_cfwall
**NOTE:**

* It is recommended that the Asus Merlin firmware is used. This is an optional firmware for the router with some significant improvements but still close enough to the original to be stable and recognisable.

* The Asus builtin firewall should be disabled since they might interfer with this set of rules.

## SUMMARY

This is a set of scripts to block access to an Asus router on country level. This is accomplished by using iptable rules. All countries other than those specified ina  white list are blocked.


## DESCRIPTION

These files are meant to be stored under the "/jffs" partition on a Asus router. This partition is an optional partition that has to first be enabled in the Asus configuration.

The proposed setup is to store all files in /jffs/firewall

The IP sets for countries that are marked for the whitelist are automatically downloaded from http://www.ipdeny.com/ by the scripts. Once downloaded on the router the sets are updated once every 30 days. Note that the updates only happens at a reboot so if a router is up more than 30 days the country sets might be older than that.

When using the Merlin variant scripts that are stored under /jffs/scripts will be automatically run when the router is rebooted.

## USAGE

1. After the /jffs partition has been enabled store the firewall-start script under the "/jffs/scripts" directory.

2. Store the initfw_cydrop.sh under /jffs/firewall

3. The countries to be added to the whitelistj are specified in "/jffs/firewall/white.conf" with one country per line defined by their ISO 2-letter code in lower case. At minimum the home country needs to be added in the whitelist if you want to be able to access anything from the outside of the router such as a server that are behind the router.

*NOTE 1:* All dropped packets are added in the log with the prefix "CYDROP:" (As in **C**ountr**Y** **DROP**)

## FILES

* firewall-start . Utility script to be put in the scripts directory to run the setup script at reboot

* initfw_cydrop.sh  . Setup script to create rules

* lsfro.sh . Utility script to list FORWARD table chains

* lsinp.sh . Utility script to list INPUT table chains
