#!/bin/bash

PAMPERO_DB_SERVER='pampero.itba.edu.ar'
PAMPERO_DB_ADDRESS='bd1.it.itba.edu.ar'
PAMPERO_DB_PORT='5432'
TUNNEL_DB_PORT='5431'

if [ $# -lt 1 ]
then
	echo "Must provide username for $PAMPERO_DB_SERVER"
	exit 1
fi

ssh $1@$PAMPERO_DB_SERVER -L $TUNNEL_DB_PORT:$PAMPERO_DB_ADDRESS:$PAMPERO_DB_PORT << HERE
 ping localhost
HERE