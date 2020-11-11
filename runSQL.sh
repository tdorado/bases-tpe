#!/bin/bash

TUNNEL_DB_PORT='5431'

if [ $# -lt 1 ]
then
	echo "Must provide username"
	exit 1
fi

psql -h localhost -p $TUNNEL_DB_PORT -U $1 -f funciones.sql PROOF