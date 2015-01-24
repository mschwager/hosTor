#!/bin/sh

sethostname()
{
    new_hostname=$1
    old_hostname=$2
    hostname $new_hostname
    hostname > /etc/hostname
    sed 's/^127\.0\.1\.1\s'$old_hostname'.*/127.0.1.1\t'$new_hostname'/' -i /etc/hosts
}

usage()
{
    echo "usage: $0 [-M] [-h] master-ip hostname"
    echo "optional arguments:"
    echo "  -M,             This is the master deployment"
    echo "  -h,             Print this message"
    echo "required arguments:"
    echo "  master-ip,      IP of the master deployment"
    echo "  hostname,       Hostname for this deployment (also minion id)"

    exit 0
}

# Defaults
master_ip=""
master=""
new_hostname=""
old_hostname=$(hostname)

# Reset in case getopts has been used previously in the shell.
OPTIND=1

# Parse arguments
while getopts "hM" opt; do
case "$opt" in
    h) usage;;
    M) master="-M";;
    *) usage;;
esac
done

shift $((OPTIND-1))

if [ "$#" -ne 2 ]; then
    echo "Please specify the master-ip and hostname"
    exit 1
fi

master_ip=$1
new_hostname=$2

sethostname $new_hostname $old_hostname

curl -L https://bootstrap.saltstack.com -o install_salt.sh
sh install_salt.sh $master -A $master_ip

if [ $master ]; then
    mkdir -p /srv/salt
    cp -R salt/* /srv/salt/
fi

