#!/bin/sh
pssh -P -h nodes.txt pwd
pssh  -h nodes.txt "yum upgrade -y"
