#!/bin/bash

for drive in /dev/sd?; do 
  echo "$drive:"
  sudo smartctl -a $drive | grep -i temperature
  echo ""
done
