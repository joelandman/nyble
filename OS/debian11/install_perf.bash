#!/bin/bash
. /root/kv.data
cd /root/k/linux-${KV}/tools
make cgroup
cp cgroup/cgroup_event_listener /usr/bin
cd perf
make DOCBOOK_XSL_172=1 install
cd /root/k ; cp -fr lib64/* /lib64; cp -fr etc/* /etc
cd /root/k/bin ; mv -f perf /usr/bin/perf_${KV}
cd /root/k/bin ; cp -vf perf-read* trace /usr/bin
cd /root/k/share ; cp -rv perf-core /usr/share
cd /usr/share ; mv perf-core perf_${KV}-core
cd /root/k ; cp -rf libexec /
cd /root
rm -rf /root/k  /root/kv.data
