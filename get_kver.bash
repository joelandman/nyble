#!/bin/bash
T=$1
dpkg -l --root=$T | grep linux-image- | grep -v meta | perl -lane 'print $F[1] =~ /linux-image-(.*)/'
