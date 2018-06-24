#!/bin/sh
# -----------------------------------------------------------------
# PURPOSE: 
# Setup a netfilter whitelist based on IP address origin country. 
# Only packets from countries in the whitelist are allowed through.
#
# The countries are specified in "white.conf" with one country 
# per line defined by their ISO 2-letter code in lower case.
#
# Normally this only contains your home country.
# If "white.conf" does not exist it is created and initialized 
# with a default country as specified in the shell variable
# "default_country" the top of this script.
#
# There is no formal limit on the amount of countries in the
# whitelist but from a practical point of view there is of course
# no point in using a whitelist if too many countries are added!
#
# Author: Johan Persson (johan162@gmail.com)
# Date: 4 feb 2017
# Updated: 11 june 2017 for AC68U
# -----------------------------------------------------------------

# We need to have the extension set module loaded
modprobe xt_set.ko

# Default country for whitelist (se=Sweden)
default_country="se"

# Flag if SSH DDOS attack protection firewall rule should be installed.
# This will block IP addresses with more more than 3 failed 
# attempts on SSH login in 30 minutes.
# Since the rule is added after the whitelist check this will only apply
# to countries in the whitelist. 
# Note that this is not a guarantee to stop a massive DoS attack since the 
# dynamic list with netfilter by default only holds the last 100 ip addresses. 
# A massive attack with spoofed IP addressed can quickly fill up the 
# dynamic list and push old IP addresses of the cliff so that the 
# that the required number of hits for dropping is never reached for 
# individual IP addresses.
install_sshdrop=0

# Start in the firewall directory
cd /jffs/firewall 

# If the whitelist exists we still renew the IIP-addresses every 60 days
if [ -e whitelist.ipset  ]; then
    find whitelist.ipset  -mtime +120 -exec rm {} \;
fi

# If no whitelist ipset exists then setup a new set
if [ ! -e whitelist.ipset  ]; then

    # Make sure a proper country list exists and if not create 
    # a default one allowing Swedish IP - numbers
    if [ ! -e white.conf ]; then
        logger  "CYDROP: Creating new default 'white.conf'"
        echo $default_country > white.conf
    fi

    logger  "CYDROP: No saved whitelist. Creating a new whitelist ..."
    rm -f *-aggregated.zone*

    # Pull the latest IP set for all countries in the whitelist
    for i in  $(cat white.conf) ; do
        logger  "CYDROP: Getting $i aggregated IP list..."
        wget -q -P . http://www.ipdeny.com/ipblocks/data/aggregated/$i-aggregated.zone
    done

    # Initialize a new ipset   whitelist set
    ipset destroy whitelist > /dev/null 2>&1
    ipset create whitelist hash:net family inet hashsize 131072 maxelem 65536

    # Allow reserved broadcast and VPN networks to passes over eth1
    ipset add whitelist 0.0.0.0/8
    ipset add whitelist 10.0.0.0/8

    for c in  $(cat white.conf) ; do
        logger  "CYDROP: Adding $c to whitelist ..."
        for ip in $(cat $c-aggregated.zone ); do ipset add whitelist $ip; done
    done

    ipset   save whitelist > whitelist.ipset  
    logger  "CYDROP: New whitelist saved."

    cd /

else

    # First check if whitelist is already installed in netfilter
    echo iptables  -L FORWARD | grep whitelist > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        logger  "CYDROP ERROR: Whitelist is in use. No changes made" >&2
        exit 1
    else
        ipset destroy whitelist > /dev/null 2>&1
        logger  "CYDROP: Initializing whitelist using saved country address ranges"
        ipset restore < whitelist.ipset 
    fi

fi


# Add new netfilter chains.
logger  "CYDROP: Checking if CYDROP chain already exists"
iptables   -L CYDROP > /dev/null 2>&1

if [ $? -eq 1 ]; then
    # Create the CYDROP chain if it doesn't exist
    iptables   -N CYDROP
    iptables   -A CYDROP -m state --state NEW -j LOG --log-prefix "CYDROP "
    iptables   -A CYDROP -j DROP
    logger  "CYDROP: Added new CYDROP chain"
else
    logger  "CYDROP: CYDROP chain already exists. No changes made"
fi

if [ $install_sshdrop -eq 1 ]; then
    logger  "SSHDROP: Checking if existsing sshdrop exists"
    iptables   -L sshdrop > /dev/null 2>&1
    # Only add the chain if it doesn't already exist
    if [ $? -eq 1 ]; then
        iptables   -N sshdrop
        iptables   -A sshdrop -j LOG --log-prefix "sshdrop "
        iptables   -A sshdrop -j DROP
        logger  "SSHDROP: Added new SSHDROP chain"
    else
        logger  "SSHDROP: sshdrop chain exists. No changes made"
    fi
fi

# Check that rule doesn't exist already
# We add chain rules both to the INPUT and FORWARD predefined chains
iptables -L FORWARD | grep whitelist > /dev/null 2>&1
if [ $? -eq 1 ]; then
    # Chain rule doesn't already exist
    iptables   -I FORWARD 3 -p ALL -i eth0 -m set ! --match-set whitelist src -j CYDROP

    iptables   -I INPUT 1 -m state --state RELATED,ESTABLISHED -j ACCEPT
    iptables   -A INPUT -p ALL -i eth0 -m set ! --match-set whitelist src -j CYDROP

    logger  "CYDROP: Whitelist sucessfully installed" >&2
else
    logger  "CYDROP ERROR: Whitelist chain already installed. No changes made" >&2
    exit 1
fi


if [ $install_sshdrop -eq 1 ]; then
    # Check that rule doesn't exist already
    iptables   -L FORWARD | grep sshdrop > /dev/null 2>&1
    if [ $? -eq 1 ]; then
        logger  "SSHDROP: Adding FORWARD chain rule. Drop if > 3 attempts in 60min ..."
        iptables   -A FORWARD -p tcp --dport 22 -m state --state NEW -m recent --name sshblock --update --seconds 3600 --hitcount 4  -j sshdrop
        iptables   -A FORWARD -p tcp --dport 22 -m state --state NEW -m recent --name sshblock --set
    else
        logger  "SSHDROP ERROR: SSHDROP already installed." >&2
    fi
fi

logger  "CYDROP: Initialization sucessfull!"

