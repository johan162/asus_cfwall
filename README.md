# README asus_cfwall.
**NOTE:**

Version: 24 june 2018

* It is recommended that the Asus Merlin firmware is used. This is an optional firmware for the router with some significant improvements but still close enough to the original to be stable and recognisable.

* The Asus built-in firewall should be disabled since they might interfer with this set of rules.

## SUMMARY

This is a set of scripts to block access to an Asus router on country level. This is accomplished by using iptable rules. All countries other than those specified in a white list are blocked. This adds an extra layer of protection from script-kiddies since most home router installations are used within a single country.


## DESCRIPTION

These files are meant to be stored under the "/jffs" partition on a Asus router. This partition is an optional partition that has to first be enabled in the Asus configuration.

The proposed setup is to store all files in /jffs/firewall

The IP sets for countries that are marked for the whitelist are automatically downloaded from http://www.ipdeny.com/ by the scripts. Once downloaded on the router the sets are updated once every 30 days. Note that the updates only happens at a reboot so if a router is up more than 30 days the country sets might be older than that.

When using the Merlin variant scripts that are stored under /jffs/scripts will be automatically run when the router is rebooted.

## SUPPORTED ROUTERS

The script comes in two variants

1. AC66x. For any routers in the AC66x series (such as AC66U, AC66N)

2. AC68x. For newer routers in the AC68x series (such AS AC68U). This family uses a newer version of iptables and Linux kernel and hence requires some minor but incompatible changes from the version for AC66

The service start script is exactly the same

## USAGE

**NOTE:** *Remember to first enable the  "/jffs" partition in the router settings and disable the routers firewall.*

1. After the "/jffs" partition has been enabled store the *firewall-start* script under the "/jffs/scripts" directory.

2. Create the directory "/jffs/firewall". Depending on your router copy the approprate version of "initfw_cydrop.sh" to "/jffs/firewall"

3. The countries to be added to the whitelistj are specified in "/jffs/firewall/white.conf" with one country per line defined by their ISO 2-letter code in lower case. At minimum the home country needs to be added in the whitelist if you want to be able to access anything from the outside of the router such as a server that are behind the router.

*NOTE 1:* All dropped packets are added in the log with the prefix "CYDROP:" (As in **C**ountr**Y** **DROP**)

## FILES

* firewall-start . Utility script to be put in the "/jffs/scripts" directory to run the setup script at (re)-boot.

* "AC66x/initfw_cydrop.sh"  . Setup script to create rules for the AC66x family.

* "AC68x/initfw_cydrop.sh"  . Setup script to create rules for the AC68x family.

* "lsfor.sh" . Utility script to list FORWARD table chains

* "lsinp.sh" . Utility script to list INPUT table chains
