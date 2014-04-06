#!/bin/bash

CHEF_ENVIRONMENT='mysite_dev'
CHEF_RUN_LIST='recipe[mysite]'
CHEF_CONFIG='/etc/chef/client.rb'
CHEF_SERVER_URL=''
CHEF_VALIDATOR_NAME='chef-validator'
CHEF_VALIDATOR_KEY='/etc/chef/validator.pem'

LOG_EMAIL=''
LOG_LEVEL='info'
LOG_PATH="/var/tmp/chef_bootstrap_`date -u +'%F_%H%M'`.log"

start () {
	
	if [[ ! -e /usr/bin/chef-client ]]; then
		curl -L https://www.opscode.com/chef/install.sh | sudo bash
	fi
	
	if [[ -z $CHEF_RUN_LIST ]]; then
		echo "No run list was defined!"
		exit 1
	else
		options="-o '$CHEF_RUN_LIST' "
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
		CHEF_CONFIG="/var/tmp/client-$$.rb"
		echo "validation_client_name '$CHEF_VALIDATOR_NAME'" > $CHEF_CONFIG
	fi
	options+="-c '$CHEF_CONFIG' "

	options+="-l $LOG_LEVEL -L $LOG_PATH"
				
	cmd="chef-client $options"
	echo "Running:  $cmd";
	eval $cmd; return_code=$?
	
	if [[ -e $LOG_PATH && -e $LOG_EMAIL ]]; then
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