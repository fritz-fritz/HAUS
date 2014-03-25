#!/bin/bash
##########################################################################
#  install.sh
#  
#  Run this to install HAUS - Home AUtomation System
#
#  Created by Roland Fritz on 3/20/14.
#
##########################################################################
# Declare functions
function quit {
    echo -e "\nYou have a dynamic network and no IFTTT account."
    echo "Unfortunately, you will have to fix this on your own."
    echo "Try researching \"DHCP Reservations\" or creating a free account at IFTTT.com"
    exit
}

function quitsendmail {
    echo -e "\nYou do not have sendmail configured."
    echo "Unfortunately, you will have to fix this on your own."
    exit
}

function quitcount {
    echo -e "\nTo use Bluetooth sensing you must enter MAC addresses."
    echo "Please try again."
exit
}

##########################################################################
# Check for root access and confirm installation
echo -e "\n\n\t\t\tHAUS\n\t\tHome AUtomation System\n"

if [ "$(id -u)" != "0" ]; then
    echo "Sorry, you are not the superuser. please execute with sudo to continue."
    exit 1
fi

echo -e "Project HAUS is designed to intelligently control\nthe hardware in your home in a seamless way."


# prompt to continue
while true; do
    read -p "Do you wish to install? (y/n) " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

##########################################################################
# Check for dependencies and install if possible

# Check for curl and install if necessary
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' curl 2> /dev/null | grep "install ok installed" || echo "fail")
echo " * Checking for curl: "$PKG_OK
if [ "fail" == "$PKG_OK" ]; then
echo -n "No curl. Setting up curl: "
sudo apt-get --force-yes --yes install curl 2> /dev/null && echo "Success" || echo "fail"
fi

# Check for bluetooth and install if necessary
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' bluez 2> /dev/null | grep "install ok installed" || echo "fail")
echo " * Checking for bluetooth stack (bluez): "$PKG_OK
if [ "fail" == "$PKG_OK" ]; then
echo -n "No bluetooth stack. Setting up bluez: "
sudo apt-get --force-yes --yes install bluez 2> /dev/null && echo "Success" || echo "fail"
fi

# Check for python-setuptools and install if necessary
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' python-setuptools 2> /dev/null | grep "install ok installed" || echo "fail")
echo " * Checking for python-setuptools: "$PKG_OK
if [ "fail" == "$PKG_OK" ]; then
echo -n "No python-setuptools. Attempting to install: "
sudo apt-get --force-yes --yes install python-setuptools 2> /dev/null && ( echo "Success"; setuptools=true ) || ( echo "fail"; setuptools=false )
fi

# Check for python-dev and install if necessary
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' python-dev 2> /dev/null | grep "install ok installed" || echo "fail")
echo " * Checking for python-dev: "$PKG_OK
if [ "fail" == "$PKG_OK" ]; then
echo -n "No python-dev. Attemping to install: "
sudo apt-get --force-yes --yes install python-dev 2> /dev/null && ( echo "Success"; dev=true ) || ( echo "fail"; dev=false )
fi

# Attempt install of Ouimeaux (it does it's own amazing job of meeting requirements)
if $setuptools && $dev && ! $(which wemo > /dev/null 2>&1); then
    echo -n "Attempting to install Ouimeaux (to control WeMo): "
    easy_install ouimeaux 2> /dev/null && ( echo "Success"; wemo=true ) || ( echo "fail"; wemo=false )
elif $setuptools && $dev; then
    echo " * Ouimeaux is already installed and configured"
    wemo=true
fi

# Check for bluetooth and install if necessary
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' bluez 2> /dev/null | grep "install ok installed" || echo "fail")
echo " * Checking for bluetooth stack (bluez): "$PKG_OK
if [ "fail" == "$PKG_OK" ]; then
    echo -n "No bluetooth stack. Setting up bluez: "
    sudo apt-get --force-yes --yes install bluez 2> /dev/null && echo "Success" || echo "fail"
fi

##########################################################################
# Now figure out what Presence Detection Method we will use...
if (( $(hcitool dev 2> /dev/null | wc -l) > 1 )); then
    bluetooth=true
else
    bluetooth=false
    # prompt for IFTTT
    while true; do
        read -p "Do you have an IFTTT account? (y/n) " yn
        case $yn in
            [Yy]* ) ifttt_location="true" ; break;;
            [Nn]* ) ifttt_location="false" ; break;;
            * ) echo "Please answer yes or no.";;
        esac
    done

    # prompt for network type
    while [[ $ifttt_location == "false" ]]; do
        read -p "Do you have static IP addresses for your phones? (y/n) " yn
        case $yn in
            [Yy]* ) network="true" ; break;;
            [Nn]* ) network="false" ; quit;;
            * ) echo "Please answer yes or no.";;
        esac
    done


fi

if $wemo && (( $(wemo --timeout=10 --no-cache list 2> /dev/null | wc -l) > 0 )); then
    echo "WeMo Switches Detected"
    #echo $(wemo list | grep "Switch")
    wemo --no-cache list | grep "Switch"
else
    echo -e "No WeMo Switch Detected"
    wemo=false
    # prompt to continue with IFTTT
    if [[ "$ifttt_location" == "" ]]; then
        while true ; do
            read -p "Do you have an IFTTT account? (y/n) " yn
            case $yn in
                [Yy]* ) ifttt_wemo="true" ; break;;
                [Nn]* ) ifttt_wemo="false" ; break;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    else
        #This overides local wemo control if we don't find a switch
        echo "...resorting to IFTTT control"
        ifttt_wemo=$ifttt_location
    fi
    # Now we know for sure if there is an IFTTT account
    echo
    # If using IFTTT to control WeMo, check for sendmail
    if (( $(which sendmail | wc -l) > 0 )); then
        sendmail=true
    else
        quitsendmail
    fi
fi

##########################################################################
# Now we begin generating script. Categorized by Presence Detection Method

# Create header and prompt for variables
cat $PWD/resources/header.sh > HAUS.sh #We are overwriting if the file exists
read -p "Which WeMo switch should we control? " switch
echo -e "\nwemo_switch=\"${switch}\" #Enter the name of your switch (only 1 for now)" >> HAUS.sh
read -p "How many seconds do we wait between runs? " wait
echo -e "sleeptime=\"${wait}\" #in seconds" >> HAUS.sh
read -p "How many minutes should we buffer the sunrise and sunset? " buffer
echo -e "buffer=${buffer} #Time buffer in minutes for sunset and sunrise" >> HAUS.sh
read -p "What is your weather.yahoo.com location code (eg. Wash. DC = 2514815)? " location
echo -e "l=${location} # This is found from weather.yahoo.com after looking up your location.  The last numbers in the URL will be this ( Washington, DC = 2514815 )\n" >> HAUS.sh
echo -e "# Leave these variables blank\nprevious_condition=\"\"\nprevious_date=\"\"\nset_condition=\"\"\n" >> HAUS.sh

# for testing...
#wemo=true
#bluetooth=true
#ifttt_wemo="true"

if $bluetooth && $wemo; then
    #Bluetooth Location / Local WeMo Control
    echo "Using Bluetooth Location & Local WeMo Control"

    #get the MAC addresses
    read -p "How many bluetooth devices to detect? " count
    if (($count == 0)); then quitcount; fi
    for (( j=0 ; j < $count ; j++ ))
    do
        read -p "Set MAC$j = " address
        echo -e "MAC${j}=\"${address}\"" >> HAUS.sh
    done

    cat $PWD/resources/startcurrent.sh >> HAUS.sh
    #echo "current_condition=\$(wemo -v switch \"${switch}\" status)" >> HAUS.sh
    echo -e "count=0\nwhile (( \$count < 2 )) && ( [[ \$current_condition == \"\" ]] || [[ \$current_condition == \"x\" ]] )\ndo" >> HAUS.sh
    echo -e "current_condition=\$(wemo -v --timeout=2 switch \"\${wemo_switch}\" status >/tmp/wemo.tmp 2>&1 && ( cat /tmp/wemo.tmp; rm /tmp/wemo.tmp ) || ( ( if [[ \$previous_condition == \"\" ]] && (( \$count < 1 )); then echo \"x\"; elif [[ \$previous_condition == \"\" ]]; then exit; else echo \"\$previous_condition\"; fi ); wemo clear > /dev/null 2>&1; rm /tmp/wemo.tmp ))" >> HAUS.sh
    echo -e "let count++\ndone" >> HAUS.sh
    echo "if [[ \$current_condition == \"\" ]]; then exit 1; fi" >> HAUS.sh
    cat $PWD/resources/currentcondition.sh >> HAUS.sh

    #now based on the count adjust this line...
    echo "# Bluetooth sensing of devices (btPing.sh must be in sudoers file)" >> HAUS.sh
    echo "sudo ./btPing.sh $(bash macarg.sh $count) > presence.tmp" >> HAUS.sh

    cat $PWD/resources/bluetoothpresence.sh >> HAUS.sh
    cat $PWD/resources/astronomy.sh >> HAUS.sh
    cat $PWD/resources/wemocontrol.sh >> HAUS.sh
    cat $PWD/resources/cleanupbluetooth.sh >> HAUS.sh

elif $bluetooth && [[ "$ifttt_wemo" == "true" ]]; then
    #Bluetooth Location / IFTTT WeMo Control
    echo "Using Bluetooth Location & IFTTT WeMo Control"
    echo "# If using gmail with IFTTT fill in login here" >> HAUS.sh
    read -p "What is your gmail username (eg example@gmail.com)? " username
    echo -e "username=\"${username}\"" >> HAUS.sh
    read -p "What is your password? " password
    echo -e "password=\"${password}\"" >> HAUS.sh
    read -p "What is your gmail WeMo Status Filter? " wemo_filter
    echo -e "wemo_filter=\"${wemo_filter}\"" >> HAUS.sh

    #get the MAC addresses
    read -p "How many bluetooth devices to detect? " count
    if (count == 0); then quitcount; fi
    for (( j=0 ; j < $count ; j++ ))
    do
    read -p "Set MAC$j = " address
    echo -e "MAC${j}=\"${address}\"" >> HAUS.sh
    done

    cat $PWD/resources/startcurrent.sh >> HAUS.sh
    cat $PWD/resources/fetchwemo.sh >> HAUS.sh
    cat $PWD/resources/currentcondition.sh >> HAUS.sh

    #now based on the count adjust this line...
    echo "# Bluetooth sensing of devices (btPing.sh must be in sudoers file)" >> HAUS.sh
    echo "sudo ./btPing.sh $(bash macarg.sh $count) > presence.tmp" >> HAUS.sh

    cat $PWD/resources/bluetoothpresence.sh >> HAUS.sh
    cat $PWD/resources/astronomy.sh >> HAUS.sh
    cat $PWD/resources/iftttcontrol.sh >> HAUS.sh
    cat $PWD/resources/cleanupbluetooth.sh >> HAUS.sh

elif [[ "$ifttt_location" == "true" ]] && $wemo; then
    #IFTTT Account for Location / Local WeMo Control
    echo "Using IFTTT Account for Location & Local WeMo Control"
    echo "# If using gmail with IFTTT fill in login here" >> HAUS.sh
    read -p "What is your gmail username (eg example@gmail.com)? " username
    echo -e "username=\"${username}\"" >> HAUS.sh
    read -p "What is your password? " password
    echo -e "password=\"${password}\"" >> HAUS.sh
    read -p "What is your gmail IFTTT Location Status Filter? " ifttt_filter
    echo -e "presence_filter=\"${ifttt_filter}\"" >> HAUS.sh

    cat $PWD/resources/startcurrent.sh >> HAUS.sh
    cat $PWD/resources/fetchoccupied.sh >> HAUS.sh
    echo -e "count=0\nwhile (( \$count < 2 )) && ( [[ \$current_condition == \"\" ]] || [[ \$current_condition == \"x\" ]] )\ndo" >> HAUS.sh
    echo -e "current_condition=\$(wemo -v --timeout=2 switch \"\${wemo_switch}\" status >/tmp/wemo.tmp 2>&1 && ( cat /tmp/wemo.tmp; rm /tmp/wemo.tmp ) || ( ( if [[ \$previous_condition == \"\" ]] && (( \$count < 1 )); then echo \"x\"; elif [[ \$previous_condition == \"\" ]]; then exit; else echo \"\$previous_condition\"; fi ); wemo clear > /dev/null 2>&1; rm /tmp/wemo.tmp ))" >> HAUS.sh
    echo -e "let count++\ndone" >> HAUS.sh
    echo "if [[ \$current_condition == \"\" ]]; then exit 1; fi" >> HAUS.sh
    cat $PWD/resources/currentcondition.sh >> HAUS.sh
    cat $PWD/resources/parseoccupied.sh >> HAUS.sh
    echo -e "# Now lets log the current status at home:\necho \"Current status at home: \"\$occupied" >> HAUS.sh
    cat $PWD/resources/astronomy.sh >> HAUS.sh
    cat $PWD/resources/wemocontrol.sh >> HAUS.sh
    cat $PWD/resources/cleanupifttt.sh >> HAUS.sh

elif [[ "$ifttt_location" == "true" ]] && [[ "$ifttt_wemo" == "true" ]]; then
    #IFTTT Account for Location AND WeMo
    echo "Using IFTTT Account for Location AND WeMo"
    echo "# If using gmail with IFTTT fill in login here" >> HAUS.sh
    read -p "What is your gmail username (eg example@gmail.com)? " username
    echo -e "username=\"${username}\"" >> HAUS.sh
    read -p "What is your password? " password
    echo -e "password=\"${password}\"" >> HAUS.sh
    read -p "What is your gmail IFTTT Location Status Filter? " ifttt_filter
    echo -e "presence_filter=\"${ifttt_filter}\"" >> HAUS.sh
    read -p "What is your gmail WeMo Status Filter? " wemo_filter
    echo -e "wemo_filter=\"${wemo_filter}\"" >> HAUS.sh

    cat $PWD/resources/startcurrent.sh >> HAUS.sh
    cat $PWD/resources/fetchwemo.sh >> HAUS.sh
    cat $PWD/resources/fetchoccupied.sh >> HAUS.sh
    cat $PWD/resources/currentcondition.sh >> HAUS.sh
    cat $PWD/resources/parseoccupied.sh >> HAUS.sh
    echo -e "# Now lets log the current status at home:\necho \"Current status at home: \"\$occupied" >> HAUS.sh
    cat $PWD/resources/astronomy.sh >> HAUS.sh
    cat $PWD/resources/iftttcontrol.sh >> HAUS.sh
    cat $PWD/resources/cleanupifttt.sh >> HAUS.sh

elif [[ "$network" == "true" ]] && $wemo; then
    #Ping IP Addresses / Local WeMo Control
    echo "Using Ping IP Addresses & Local WeMo Control"

    # Still need to make this section
    #echo "current_condition=\$(wemo -v --timeout=2 switch \"${switch}\" status >/tmp/wemo.tmp 2>&1 && ( cat /tmp/wemo.tmp; rm /tmp/wemo.tmp ) || ( echo \"\\\$previous_condition\"; wemo clear > /dev/null 2>&1; rm /tmp/wemo.tmp ))" >> HAUS.sh

elif [[ "$network" == "true" ]] && [[ "$ifttt_wemo" == "true" ]]; then
    #Ping IP Addresses / IFTTT WeMo Control
    echo "Using Ping IP Addresses & IFTTT WeMo Control"
    echo "# This method is very inaccurate. Fill in IP addresses to check:" >> HAUS.sh
    read -p "What is the first IP to check? " ip1
    echo -e "ip1=\"${ip1}\"" >> HAUS.sh
    read -p "What is the second IP to check? " ip2
    echo -e "ip2=\"${ip2}\"" >> HAUS.sh

    cat $PWD/resources/startcurrent.sh >> HAUS.sh
    cat $PWD/resources/fetchwemo.sh >> HAUS.sh
    cat $PWD/resources/ping.sh >> HAUS.sh
    cat $PWD/resources/currentcondition.sh >> HAUS.sh
    echo -e "# Now lets log the current status at home:\necho \"Current status at home: \"\$occupied" >> HAUS.sh
    cat $PWD/resources/astronomy.sh >> HAUS.sh
    cat $PWD/resources/iftttcontrol.sh >> HAUS.sh
    cat $PWD/resources/cleanupping.sh >> HAUS.sh

else
    quit
fi

##########################################################################
# Now we will set permissions, create upstart job, and launch daemon

if $bluetooth; then
set -e #this exits the script on error to prevent problems

# set permissions on the btPing file to prevent others from editing it since it will be run as sudo without password (just in case)
sudo chmod 711 btPing.sh
sudo chown $(cat /etc/passwd | grep :0 | awk -F':' '{print $1}'):$(cat /etc/group | grep :0 | awk -F':' '{print $1}') btPing.sh

# now add btPing.sh to the sudoers file (CRUCIAL to get it to work)
# this is done using visudo to protect the sudoers file
printf "a\n$(whoami) ALL=(ALL) NOPASSWD: $PWD/btPing.sh\n.\n\nw\nq\n" | sudo EDITOR="ed" visudo
fi

# test if linux before prompting to continue
if ( uname -a | grep -i "linux"  >/dev/null 2>&1 ); then
    # now generate the upstart job
    cat resources/HAUS.conf > HAUS.conf
    echo "cd $PWD" >> HAUS.conf
    echo "exec sudo bash HAUS.sh" >> HAUS.conf
    echo "end script" >> HAUS.conf

    # now move into place
    sudo mv HAUS.conf /etc/init/HAUS.conf

    # after adding upstart job to /etc/init/ we must reload to register it
    sudo initctl reload-configuration
else
    echo "Failed to create upstart job."
    echo "You must manually create upstart job or manually start the script."
fi

##########################################################################
# Success!

echo -e '\n\nCongratulations! You successfully installed HAUS!'

