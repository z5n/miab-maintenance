#!/bin/bash
#
# SCRIPT: maintenance.sh
# AUTHOR: z5n
# DATE:   2021-11-30
#
# PLATFORM: Not platform dependent
#
# PURPOSE: Runs maintenance on a Mailinabox server.
#
# NOTES: This file must be contained in a directory matching the name of the IP of your MIAB server.
##########################################################

echo Mailinabox Maintenance Script
echo -------------------

############################ environment variables ############################

# Start duration of script (part of a duration counter mechanism to time how long it takes to execute this entire script).
    SECONDS=0

# Locates the name of the immediate parent directory and assigns it to variable $mydir.
    var=$(pwd)
    mydir="$(basename $PWD)"

# Sets the target server based on the name of the immediate parent directory — $mydir.
    export targetserver=$mydir
    echo "The target server is: $targetserver"

# Gets the current month, day, and year.
    yyyy=$(date +"%Y")
    mm=$(date +"%m")
    dd=$(date +"%d")

# Trusted IP list (to whitelist for ufw):
    ip=$(curl -s "http://myexternalip.com/raw")
    
############################### OS select ################################

# Assigns each operating system to a value for selection below.
    unix=0
    windows=1

# Starts OS select prompt.
    echo "What operating system are you running?"
    echo "UNIX = 0"
    echo "WINDOWS = 1"
    echo ""
    read -p 'OS: ' operatingsystem

# Starts credential input prompt.
    echo "Provide your credentials for the server below."
    read -p 'Username: ' username
    read -sp 'Password: ' password
    export username
    export password
    echo ""

# valid credential check (for unix)
    if [[ "$operatingsystem" == 0 ]]; then
        bash <(
            curl -sL https://gist.githubusercontent.com/z5n/5786caf3e681ea936deee118a06ff36e/raw/backup-config-off-gist.sh
            )
    fi

# valid credential check (for windows)
    if [[ "$operatingsystem" == 1 ]]; then
        bash <(
            curl -sL https://gist.githubusercontent.com/z5n/5786caf3e681ea936deee118a06ff36e/raw/backup-config-off-gist.bat
            )
    fi

######################### whitelist IPs - ufw ########################

    sshconnection="ssh root@$targetserver"
    command="sudo ufw insert 1 allow from $ip"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done
    
    echo "$ip - whitelisted!"

######################### storage management ########################

# Connects to remote server and runs the following commands.
    sshconnection="ssh root@$targetserver"
    command="journalctl --vacuum-time=1d"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done
    echo "Purged journal log files (preserved the last 1 day(s))..."
    
    sshconnection="ssh root@$targetserver"
    command="rm -rf /home/user-data/owncloud-backup/*"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done
    echo "Purged the contents of owncloud backups directory..."

# End of script (echo "" is whitespace).
    echo ""
    echo ""
    echo "The storage management script has run successfully."
    echo ""
    echo ""

    # until logout; do
    # echo "Error, retrying 'logout' in 10 seconds..."
    # sleep 10
    # done
    # echo "Logged out of remote server successfully..."

########################### postgrey regex check ###########################

# Sets the touch date string for resetting the /etc/postgrey/whitelist_clients file.
    touchdate=$yyyy$mm${dd}0000.00

cat > temp_regex <<\EOF
cd /etc/postgrey
file=whitelist_clients

if grep -q regex "$file"
    then
        echo "Regular expression string found within '$file' file."
else
    echo "Unable to locate regular expression string. Altering the file..."
fi

cat > /etc/postgrey/whitelist_clients <<EOF
# postgrey whitelist for mail client hostnames
# --------------------------------------------
# put this file in /etc/postfix or specify its path
# with --whitelist-clients=xxx
#
# postgrey version: ##VERSION##, build date: ##DATE##

/.*/ # regex

# greylisting.org: Southwest Airlines (unique sender, no retry)
southwest.com
# greylisting.org: isp.belgacom.be (wierd retry pattern)
isp.belgacom.be
# greylisting.org: Ameritrade (no retry)
ameritradeinfo.com
# greylisting.org: Amazon.com (unique sender with letters)
amazon.com
# 2004-05-20: Linux kernel mailing-list (unique sender with letters)
vger.kernel.org
# 2004-06-02: karger.ch, no retry
karger.ch
# 2004-06-02: lilys.ch, (slow: 4 hours)
server-x001.hostpoint.ch
# 2004-06-09: roche.com (no retry)
gw.bas.roche.com
# 2004-06-09: newsletter (no retry)
mail.hhlaw.com
# 2004-06-09: no retry (reported by Ralph Hildebrandt)
prd051.appliedbiosystems.com
# 2004-06-17: swissre.com (no retry)
swissre.com
# 2004-06-17: dowjones.com newsletter (unique sender with letters)
returns.dowjones.com
# 2004-06-18: switch.ch (works but personnel is confused by the error)
domin.switch.ch
# 2004-06-23: accor-hotels.com (slow: 6 hours)
accor-hotels.com
# 2004-06-29: rr.com (no retry, reported by Duncan Hill)
/^ms-smtp.*\.rr\.com$/
# 2004-06-29: cox.net (no retry, reported by Duncan Hill)
/^lake.*mta.*\.cox\.net$/
# 2004-06-29: motorola.com (no retry)
mot.com
# 2004-07-01: nic.fr (address verification, reported by Arnaud Launay)
nic.fr
# 2004-07-01: verizon.net (address verification, reported by Bill Moran and Eric, adapted by Adam C. Mathews)
/^s[cv]\d+pub\.verizon\.net$/
# 2004-07-02: cs.columbia.edu (no retry)
cs.columbia.edu
# 2004-07-02: papersinvited.com (no retry)
66.216.126.174
# 2004-07-02: telekom.de (slow: 6 hours)
/^mail\d+\.telekom\.de$/
# 2004-07-04: tiscali.dk (slow: 12 hours, reported by Klaus Alexander Seistrup)
/^smtp\d+\.tiscali\.dk$/
# 2004-07-04: freshmeat.net (address verification)
freshmeat.net
# 2004-07-11: zd-swx.com (unique sender with letters, reported by Bill Landry)
zd-swx.com
# 2004-07-11: lockergnome.wc09.net (unique sender with letters, reported by Bill Landry)
lockergnome.wc09.net
# 2004-07-19: mxlogic.net (no retry, reported by Eric)
p01m168.mxlogic.net
p02m169.mxlogic.net
# 2004-09-08: intel.com (pool on different subnets) 
/^fmr\d+\.intel\.com$/
# 2004-09-17: cox-internet.com (no retry, reported by Rod Roark)
/^fe\d+\.cox-internet\.com$/
# 2004-10-11: logismata.ch (no retry)
logismata.ch
# 2004-11-25: brief.cw.reum.de (no retry, reported by Manuel Oetiker)
brief.cw.reum.de
# 2004-12-03: ingeno.ch (no retry)
qmail.ingeno.ch
# 2004-12-06: rein.ch (no retry)
mail1.thurweb.ch
# 2005-01-26: tu-ilmenau.de (no retry)
piggy.rz.tu-ilmenau.de
# 2005-04-06: polymed.ch (no retry)
mail.polymed.ch
# 2005-06-08: hu-berlin.de (slow: 6 hours, reported by Joachim Schoenberg)
rz.hu-berlin.de
# 2005-06-17: gmail.com (big pool, reported by Beat Mueller)
proxy.gmail.com
# 2005-06-23: cacert.org (address verification, reported by Martin Lohmeier)
cacert.org
# 2005-07-27: polytech.univ-mrs.fr (no retry, reported by Giovanni Mandorino)
polytech.univ-mrs.fr
# 2005-08-05: gnu.org (address verification, reported by Martin Lohmeier)
gnu.org
# 2005-08-17: ciphirelabs.com (needs fast responses, reported by Sven Mueller)
cs.ciphire.net
# 2005-11-11: lufthansa (no retry, reported by Peter Bieringer)
/^gateway\d+\.np4\.de$/
# 2005-11-23: arcor-online.net (slow: 12 hours, reported by Bernd Zeimetz)
/^mail-in-\d+\.arcor-online\.net$/
# 2005-12-29: netsolmail.com (no retry, reported by Gareth Greenaway)
netsolmail.com
# mail.likopris.si (no retry, reported by Vito Robar)
193.77.153.67
# jcsw.nato.int (several servers, no retry, reported by Vito Robar)
195.235.39
# tesla.vtszg.hr (no retry, reported by Vito Robar)
tesla.vtszg.hr
# mailgw*.iai.co.il (pool of several servers, reported by Vito Robar)
/^mailgw.*\.iai\.co\.il$/
# gw.stud-serv-mb.si (no retry, reported by Vito Robar)
gw.stud-serv-mb.si
# mail.commandtech.com (no retry, reported by Vito Robar)
216.238.112.99
# duropack.co.at (no retry, reported by Vito Robar)
193.81.20.195
# mail.esimit-tech.si (no retry, reported by Vito Robar)
193.77.126.208
# mail.resotel.be (ocasionally no retry, reported by Vito Robar)
80.200.249.216
# mail2.alliancefr.be (ocasionally no retry, reported by Vito Robar)
mail2.alliancefr.be
# webserver.turboinstitut.si (no retry, reported by Vito Robar)
webserver.turboinstitut.si
# mil.be (pool of different servers, reported by Vito Robar)
193.191.218.141
193.191.218.142
193.191.218.143
194.7.234.141
194.7.234.142
194.7.234.143
# mail*.usafisnews.org (no retry, reported by Vito Robar)
/^mail\d+\.usafisnews\.org$/
# odk.fdv.uni-lj.si (no retry, reported by Vito Robar)
/^odk.fdv.uni-lj.si$/
# rak-gentoo-1.nameserver.de (no retry, reported by Vito Robar)
rak-gentoo-1.nameserver.de
# dars.si (ocasionally no retry, reported by Vito Robar)
mx.dars.si
# cosis.si (no retry, reported by Vito Robar)
213.143.66.210
# mta?.siol.net (sometimes no or slow retry; they use intermail, reported by Vito Robar)
/^mta[12].siol.net$/
# pim-N-N.quickinspirationsmail.com (unique sender, reported by Vito Robar)
/^pim-\d+-\d+\.quickinspirationsmail\.com$/
# flymonarch (no retry, reported by Marko Djukic)
flymonarch.com
# wxs.nl (no retry, reported by Johannes Fehr)
/^p?smtp.*\.wxs\.nl$/
# ibm.com (big pool, reported by Casey Peel)
ibm.com
# messagelabs.com (big pool, reported by John Tobin)
messagelabs.com
# ptb.de (slow, reported by Joachim Schoenberg)
berlin.ptb.de
# registrarmail.net (unique sender names, reported by Simon Waters)
registrarmail.net
# google.com (big pool, reported by Matthias Dyer, Martin Toft)
google.com
# orange.fr (big pool, reported by Loïc Le Loarer)
/^smtp\d+\.orange\.fr$/
# citigroup.com (slow retry, reported by Michael Monnerie)
/^smtp\d+.citigroup.com$/
# cruisingclub.ch (no retry)
mail.ccs-cruising.ch
# digg.com (no retry, Debian #406774)
diggstage01.digg.com
# liberal.ca (retries only during 270 seconds, Debian #406774)
smtp.liberal.ca
# pi.ws (pool + long retry, Debian #409851)
/^mail[12]\.pi\.ws$/
# rambler.ru (big pool, reported by Michael Monnerie)
rambler.ru
# free.fr (big pool, reported by Denis Sacchet)
/^smtp[0-9]+-g[0-9]+\.free\.fr$/
/^postfix[0-9]+-g[0-9]+\.free\.fr$/
# thehartford.com (pool + long retry, reported by Jacob Leifman)
/^netmail\d+\.thehartford\.com$/
# abb.com (only one retry, reported by Roman Plessl)
/^nse\d+\.abb\.com$/
# 2007-07-27: sourceforge.net (sender verification)
lists.sourceforge.net
# 2007-08-06: polytec.de (no retry, reported by Patrick McLean)
polytec.de
# 2007-09-06: qualiflow.com (no retry, reported by Alex Beckert)
/^mail\d+\.msg\.oleane\.net$/
# 2007-09-07: nrl.navy.mil (no retry, reported by Axel Beckert)
nrl.navy.mil
# 2007-10-18: aliplast.com (long retry, reported by Johannes Feigl)
mail.aliplast.com
# 2007-10-18: inode.at (long retry, reported by Johannes Feigl)
/^mx\d+\..*\.inode\.at$/
# 2008-02-01: bol.com (no retry, reported by Frank Breedijk)
/^.*?.server.arvato-systems.de$/
# 2008-06-05: registeredsite.com (no retry, reported by Fred Kilbourn)
/^(?:mail|fallback-mx)\d+.atl.registeredsite.com$/
# 2008-07-17: mahidol.ac.th (no retry, reported by Alex Beckert)
saturn.mahidol.ac.th
# 2008-07-18: ebay.com (big pool, reported by Peter Samuelson)
ebay.com
# 2008-07-22: yahoo.com (big pool, reported by Juan Alonso)
yahoo.com
# 2008-11-07: facebook (no retry, reported by Tim Freeman)
/^outmail\d+\.sctm\.tfbnw\.net$/
# 2016-09-13: facebook (updated names, github #30)
outmail.facebook.com
# 2017-02-03: facebook (other names, reported by Harald Paulsen)
outappmail.facebook.com
# 2018-01-12: facebook (other names, reported by Pascal Herbert)
mail-mail.facebook.com
# 2009-02-10: server14.cyon.ch (long retry, reported by Alex Beckert)
server14.cyon.ch
# 2009-08-19: 126.com (big pool)
/^m\d+-\d+\.126\.com$/
# 2010-01-08: tifr.res.in (no retry, reported by Alex Beckert)
home.theory.tifr.res.in
# 2010-01-08: 1blu.de (long retry, reported by Alex Beckert)
ms4-1.1blu.de
# 2010-03-17: chello.at (big pool, reported by Jan-willem van Eys)
/^viefep\d+-int\.chello\.at$/
# 2010-05-31: nic.nu (long retry, reported by Ivan Sie)
mx.nic.nu
# 2010-06-10: Microsoft servers (long/no retry, reported by Roy McMorran)
bigfish.com
frontbridge.com
microsoft.com
# 2010-06-18: Google/Postini (big pool, reported by Warren Trakman)
postini.com
# 2011-02-04: evanzo-server.de (no retry, reported by Andre Hoepner)
/^mx.*\.evanzo-server\.de$/
# 2011-05-02: upcmail.net (big pool, reported by Michael Monnerie)
upcmail.net
# 2013-12-18: orange.fr (big pool, reported by fulax)
/^smtp\d+\.smtpout\.orange\.fr$/
# 2014-01-29: gmx/web.de/1&1 (long retry, reported by Axel Beckert)
mout-xforward.gmx.net
mout-xforward.web.de
mout-xforward.kundenserver.de
mout-xforward.perfora.net
# 2014-12-18: mail.ru (retries from fallback*.mail.ru, reported by Andriy Yurchuk)
/^fallback\d+\.mail\.ru$/
/^fallback\d+\.m\.smailru\.net$/
# French tax authority, no retry
dgfip.finances.gouv.fr 
# 2015-06-10: magisto.com (requested by postmaster)
/^o\d+\.ntdc\.magisto\.com$/
# 2015-07-23: outlook.com (github #20)
outlook.com
# 2015-08-19 (big pool)
mail.alibaba.com
mail.aliyun.com
# 2016-05-05: mtasv.net (no retry, reported by @chriscowley)
mtasv.net
# 2016-09-13: amazonses.com (github #35, #37, #38)
amazonses.com
# 2016-09-13: startcom.org (github #7)
startcom.org
# 2016-09-20: Microsoft Exchange Online (Office 365), by IP
23.103.132.0/22
23.103.136.0/21
23.103.144.0/20
23.103.198.0/23
23.103.200.0/21
40.92.0.0/14
40.107.0.0/16  
65.55.88.0/24
65.55.169.0/24
94.245.120.64/26
104.47.0.0/17
134.170.101.0/24
134.170.140.0/24
134.170.171.0/24
157.55.133.0/25
157.56.87.192/26
157.56.110.0/23
157.56.112.0/24
157.56.116.0/25
157.56.120.0/25
207.46.51.64/26
207.46.100.0/24
207.46.108.0/25
207.46.163.0/24
213.199.154.0/24
213.199.180.128/26
216.32.180.0/23
2a01:111:f400:7c00::/54
2a01:111:f400:fc00::/54
# 2016-10-28: Microsoft Exchange Online (Office 365), by Name
outbound.protection.outlook.com
# 2016-11-01: gem.godaddy.com (github #39)
gem.godaddy.com
# 2016-11-16: github long retry (github #41)
github.com
github.net
# 2017-01-06: biglumber.com, sends verification email and doesn't retry
206.222.31.58
# 2017-01-11: battle.net (long retry, #44)
battle.net
# 2017-02-09: twitter.com (big pool, #46)
twitter.com
# 2017-05-02: rrze.uni-erlangen.de (University Erlangen-Nuremberg (fau.de) uses different IPv4 and IPv6 addresses for their Mailserver)
rrze.uni-erlangen.de
# 2017-05-18: ovh.net (large pool, repoted by Tobias Hannaske)
mail-out.ovh.net
# 2017-06-07: evanzo-server.de (no retry, reported by Patrick Terlisten)
/^smarthost.*\.evanzo-server\.de$/
# 2018-01-16: Microsoft Exchange Online - German Pool (large pool, reported by Alexander Wilms)
51.4.72.0/24
51.5.72.0/24
51.4.80.0/27
51.5.80.0/27
2a01:4180:4051:0800::/64
2a01:4180:4050:0800::/64
2a01:4180:4051:0400::/64
2a01:4180:4050:0400::/64
protection.outlook.de
# 2018-04-25: Mailchimp test newsletter (unique sender each time)
systemalerts.mailchimp.com
# 2018-09-02: reflexion.net (large pool, reported by @shiz0)
reflexion.net
# 2018-09-23: Mailchimp (large pool)
205.201.128.0/20
198.2.128.0/18
148.105.0.0/16
# 2019-05-27: rekkiapp.com (large pool, #74)
rekki.com
# 2019-06-25: protonmail.ch (large pool, #76)
protonmail.ch
EOF

    echo "EOF" >> temp_regex

# for some reason everything breaks when I call cat statement on SSH connection? works everywhere else in program but here because of the EOF statement above
    # sshconnection="ssh -t root@$targetserver"
    # command="cat temp_regex"
    # combined="${command} | ${sshconnection}"
    #     until $combined; do
    #     echo "Error, retrying '${combined}' in 10 seconds..."
    #     sleep 10
    #     done

    # sshconnection="ssh root@$targetserver"
    # command="touch -m -t $touchdate /etc/postgrey/whitelist_clients"
    # combined="${sshconnection} ${command}"
    #     until $combined; do
    #     echo "Error, retrying '${command}' in 10 seconds..."
    #     sleep 10
    #     done

    until cat temp_regex | ssh -t root@$targetserver; do
    echo "Error, retrying 'cat regex | ssh root@$targetserver' in 10 seconds..."
    sleep 10
    done

    until ssh root@$targetserver touch -m -t $touchdate /etc/postgrey/whitelist_clients; do
    echo "Error, retrying 'touch -m -t $touchdate /etc/postgrey/whitelist_clients' in 10 seconds..."
    sleep 10
    done

    echo "Successfully refreshed the metadata on '/etc/postgrey/whitelist_clients' to $mm-$dd-$yyyy!"

# End of script (echo "" is whitespace).
    echo ""
    echo ""
    echo "Postgrey regular expression test complete."
    echo ""
    echo ""

    rm temp_regex

############################# version upgrade ##############################

# Connects to remote server and runs the following commands.
    sshconnection="ssh root@$targetserver"
    command="sudo apt update"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done

    sshconnection="ssh root@$targetserver"
    command="sudo apt upgrade -y"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done

    sshconnection="ssh -t root@$targetserver"
    command="curl -s https://mailinabox.email/setup.sh | sudo bash"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done


    echo "Rebooting $targetserver, halting process for 120 seconds..."
    ssh root@$targetserver reboot
    sleep 120

# End of script (echo "" is whitespace).
    echo ""
    echo ""
    echo "The upgrade script has run successfully."
    echo ""
    echo ""

############################### mailinabox backup ################################

# Calls on "backup-config-local.sh" (if running unix) file to turn on backups.
    if [[ "$operatingsystem" == 0 ]]; then
        bash <(
            curl -sL https://gist.githubusercontent.com/z5n/5786caf3e681ea936deee118a06ff36e/raw/backup-config-local-gist.sh
            )
        echo "Backup configuration successfully turned on, continuing..."
    fi

# Calls on "backup-config-local.bat" (if running windows) file to turn on backups.
    if [[ "$operatingsystem" == 1 ]]; then
        bash <(
            curl -sL https://gist.githubusercontent.com/z5n/5786caf3e681ea936deee118a06ff36e/raw/backup-config-local-gist.bat
            )
        echo "Backup configuration successfully turned on, continuing..."
    fi

# Sets the target directory based on the current month, day, and year.
    targetdir=$yyyy-$mm-$dd
    echo "The target directory is: $targetdir"

# Creates a directory according to the target directory above.
    # If the directory already exists, delete it so that a new one can be created. Useful for backing up multiple times a day.
        if [ -d $(pwd)/"$targetdir" ]; then
            echo "Directory exists already, recreating..."
            rm -rf $targetdir
            mkdir $(pwd)/"$targetdir"
        fi

        if [ ! -d $(pwd)/"$targetdir" ]; then
            mkdir $(pwd)/"$targetdir"
            echo "Directory created..."
        fi

# Connects to remote server and pulls data using above configuration.
    sshconnection="ssh root@$targetserver"
    command="rm -rf /home/user-data/backup/encrypted"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done

    sshconnection="ssh root@$targetserver"
    command="rm -rf /home/user-data/backup/cache"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done

    sshconnection="ssh root@$targetserver"
    command="/root/mailinabox/management/backup.py --full"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done

    sshconnection="scp -r root@$targetserver"
    command=":/home/user-data/backup $targetdir"
    combined="${sshconnection}${command}"
        until $combined; do
        echo "Error, retrying '${combined}' in 10 seconds..."
        sleep 10
        done

    sshconnection="ssh root@$targetserver"
    command="rm -rf /home/user-data/backup/encrypted"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done

    sshconnection="ssh root@$targetserver"
    command="rm -rf /home/user-data/backup/cache"
    combined="${sshconnection} ${command}"
        until $combined; do
        echo "Error, retrying '${command}' in 10 seconds..."
        sleep 10
        done

# Calls on "backup-config-off.sh" (if running unix) file to turn off backups.
    if [[ "$operatingsystem" == 0 ]]; then
        bash <(
            curl -sL https://gist.githubusercontent.com/z5n/5786caf3e681ea936deee118a06ff36e/raw/backup-config-off-gist.sh
            )
        echo "Backup configuration successfully turned off, continuing..."
    fi

# Calls on "backup-config-off.bat" (if running windows) file to turn off backups.
    if [[ "$operatingsystem" == 1 ]]; then
        bash <(
            curl -sL https://gist.githubusercontent.com/z5n/5786caf3e681ea936deee118a06ff36e/raw/backup-config-off-gist.bat
            )
        echo "Backup configuration successfully turned off, continuing..."
    fi

# Remove whitelisted IP(s) from ufw

ssh root@$targetserver <<\EOF
export ipdelete=$(ufw status numbered |(grep "$ip"|awk -F"[][]" '{print $2}'))
yes | sudo ufw delete $ipdelete
EOF

# End of script (echo "" is whitespace).
    echo ""
    echo ""
    echo "The backup has completed successfully."
    echo ""
    echo ""

# Print duration of script.
    if (( $SECONDS > 3600 )) ; then
        let "hours=SECONDS/3600"
        let "minutes=(SECONDS%3600)/60"
        let "seconds=(SECONDS%3600)%60"
        echo "Completed in $hours hour(s), $minutes minute(s) and $seconds second(s)" 
    elif (( $SECONDS > 60 )) ; then
        let "minutes=(SECONDS%3600)/60"
        let "seconds=(SECONDS%3600)%60"
        echo "Completed in $minutes minute(s) and $seconds second(s)"
    else
        echo "Completed in $SECONDS seconds"
    fi

# End of script.
    read -p "Press any key to close..."
