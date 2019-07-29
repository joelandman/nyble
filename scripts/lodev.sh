#!/bin/bash

if [[ -e lodev.data ]]; then
	cat lodev.data
else
	losetup -f > lodev.data
	cat lodev.data
fi
