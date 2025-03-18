#!/bin/bash
# Stuffs args into a screen

. ./env.sh

echo "Sending server on screen $SCREEN the command \"$*\"..."

sudo -u $RUNAS screen -S $SCREEN -X stuff "$*"`echo -ne '\015'`
