#!/bin/bash

ps -e -o pid,comm,nlwp | awk '$3 > 28 {print $0}'
