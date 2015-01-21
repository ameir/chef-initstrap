#!/bin/bash

# chkconfig: - 99 15
# description: Bootstrap node with Chef on startup

### BEGIN INIT INFO
# Provides: chef-initstrap
# Required-Start: $network $all
# Required-Stop: $network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description: Bootstrap node with Chef on startup
### END INIT INFO

declare -A CONFIG

CHEF_ENVIRONMENT='mysite_dev'
CHEF_RUN_LIST='recipe[mysite]'
CHEF_CONFIG_PATH='/etc/chef/client.rb'
LOG_EMAIL='you@company.com'
LOG_LEVEL='info'
LOG_PATH="/var/tmp/chef_bootstrap_`date -u +'%F_%H%M'`.log"
NODE_NAME=`hostname -f`

CONFIG['chef_server_url']="'https://chef.company.com'"
CONFIG['validation_client_name']="'chef-validator'"
CONFIG['validation_key']="'/etc/chef/validator.pem'"
CONFIG['ssl_verify_mode']=':verify_none'
CONFIG['node_name']="'$NODE_NAME'"

start () {
	
	write_config
	if [[ ! -e /usr/bin/chef-client || `/usr/bin/chef-client -v | awk -F '.' '{print ($1 == 11 && $2 < 12)}'` -eq 1 ]]; then
		installer_url='https://www.chef.io/chef/install.sh'
		curl -L -O $installer_url || wget --no-check-certificate $installer_url
		bash install.sh
	fi
	
	if [[ ! -d /etc/chef ]]; then
		echo "Directory /etc/chef not found; creating it."
		mkdir -p /etc/chef
	fi
	
	if [[ -z $CHEF_RUN_LIST ]]; then
		echo "No run list was defined!"
		exit 1
	else
		options="-r '$CHEF_RUN_LIST' "
	fi
	
	if [[ -n $CHEF_ENVIRONMENT ]]; then
		options+="-E '$CHEF_ENVIRONMENT' "
	fi

	options+="-c '$CHEF_CONFIG_PATH' -L $LOG_PATH"
	cmd="chef-client $options"
	echo "Running:  $cmd";
	eval $cmd; return_code=$?
	
	if [[ -e $LOG_PATH && -n $LOG_EMAIL ]]; then
		echo "Sending log of Chef run to $LOG_EMAIL"
		[[ $return_code -eq 0 ]] && status="Successful" || status="Failed"
		cat $LOG_PATH | mail -s "($status) Chef run for $NODE_NAME" -- $LOG_EMAIL
	fi
}

stop () {

	write_config
	knife node delete $NODE_NAME -c $CHEF_CONFIG_PATH -y
	knife client delete $NODE_NAME -c $CHEF_CONFIG_PATH -y
	rm -vf /etc/chef/client.pem
}

status () {
	echo "status not defined yet"
}

write_config () {
	mkdir -vp `dirname $CHEF_CONFIG_PATH`
	for i in "${!CONFIG[@]}"; do echo -e "$i\t\t\t${CONFIG[$i]}"; done > $CHEF_CONFIG_PATH
}

install () {
	echo -n "Installing init script..."
	script_path=`readlink -fn $0`
	chmod +x $script_path
	ln -sf $script_path /etc/init.d/chef-initstrap
	for rl in 2 3 5; do
		ln -sf ../init.d/chef-initstrap /etc/rc${rl}.d/S99chef-initstrap
	done
	echo "done."
}

case "$1" in
	start)
		start
        ;;
    stop)
    	stop
    	;;
    status)
    	status
    	;;    
    install)
    	install
    	;;        		
    *)
    	echo "Usage: $0 start|stop|status"
    	;;
esac