#!/bin/sh
DIRLIST=`ls test`

for d in `ls test`; do
	for testname in `ls test/$d/*`; do
		if [ -x "$testname" ]
		then
			mull-cxx -ld_search_path=/lib/x86_64-linux-gnu -ld_search_path=/usr/lib/x86_64-linux-gnu \
				-ld_search_path=/usr/local/lib -test-framework=Custom -mutators=all $testname
		fi
	done
done
