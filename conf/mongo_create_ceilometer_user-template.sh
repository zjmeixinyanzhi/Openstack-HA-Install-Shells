#!/bin/sh
mongo --eval 'db = db.getSiblingDB("ceilometer");db.createUser({user: "ceilometer",pwd: "123456",roles: [ "readWrite", "dbAdmin" ]})'
