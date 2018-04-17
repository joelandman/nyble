#!/bin/bash

cd /root
wget http://www.andre-simon.de/zip/ansifilter-1.12.tar.bz2
tar -xjvf ansifilter-1.12.tar.bz2
cd ansifilter-1.12
make
make install
cd ..
rm -rf ansifilter*
