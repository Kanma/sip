#! /bin/sh

if [ ! -e bin/sip ]
then
    cd $1
    $2 configure.py
fi
