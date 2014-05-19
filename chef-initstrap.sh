#!/bin/bash

### BEGIN INIT INFO
# Provides: chef-initstrap
# Required-Start: $network $all
# Required-Stop: $network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Description: Bootstrap node with Chef on startup
### END INIT INFO

CHEF_ENVIRONMENT='mysite_dev'
CHEF_RUN_LIST='recipe[mysite]'
#CHEF_CONFIG='/etc/chef/client.rb'
CHEF_SERVER_URL=''
CHEF_VALIDATOR_NAME='chef-validator'
CHEF_VALIDATOR_KEY='/etc/chef/validator.pem'

LOG_EMAIL=''
LOG_LEVEL='info'
LOG_PATH="/var/tmp/chef_bootstrap_`date -u +'%F_%H%M'`.log"

start () {
	
	if [[ ! -e /usr/bin/chef-client || `/usr/bin/chef-client -v | awk -F '.' '{print ($2 < 12)}'` -eq 1 ]]; then
		curl -L https://www.opscode.com/chef/install.sh | bash
		# TODO fallback to wget if curl isn't available
		# wget -qO- https://www.opscode.com/chef/install.sh | bash
	fi
	
	if [[ ! -d /etc/chef ]]; then
		echo "Directory /etc/chef not found; creating it"
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

	if [[ -n $CHEF_SERVER_URL ]]; then
		options+="-S '$CHEF_SERVER_URL' "
	fi

	if [[ -n $CHEF_VALIDATOR_KEY ]]; then
		options+="-K '$CHEF_VALIDATOR_KEY' "
	fi

	if [[ -z $CHEF_CONFIG ]]; then
		if [[ $CHEF_VALIDATOR_NAME != 'chef-validator' ]]; then
			CHEF_CONFIG="/var/tmp/chef-initstrap-client.rb"
			echo "validation_client_name '$CHEF_VALIDATOR_NAME'" > $CHEF_CONFIG
		else
			CHEF_CONFIG='/dev/null'
		fi
	fi
	options+="-c '$CHEF_CONFIG' "

	options+="-l $LOG_LEVEL -L $LOG_PATH"

	# /opt/chef/embedded/bin/ruby -e "require 'json';puts JSON.generate(ARGF.readlines, quirks_mode: true)"
	cmd="chef-client $options"
	echo "Running:  $cmd";
	eval $cmd; return_code=$?
	
	if [[ -e $LOG_PATH && -n $LOG_EMAIL ]]; then
		echo "Sending log of Chef run to $LOG_EMAIL"
		[[ $return_code -eq 0 ]] && status="Successful" || status="Failed"
		cat $LOG_PATH | mail -s "($status) Chef run for `hostname -f`" -- $LOG_EMAIL
	fi
}

stop () {
	echo "stop not defined yet"
}

status () {
	echo "status not defined yet"
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
    *)
    	echo "Usage: $0 start|stop|status"
    	;;
esac