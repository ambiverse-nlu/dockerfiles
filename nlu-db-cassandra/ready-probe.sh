#!/bin/bash

# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

_ip_address() {
	# scrape the first non-localhost IP address of the container
	# in Swarm Mode, we often get two IPs -- the container IP, and the (shared) VIP, and the container IP should always be first
	#ip address | awk '
	#	$1 == "inet" && $NF != "lo" {
	#		gsub(/\/.+$/, "", $2)
	#		print $2
	#		exit
	#	}
	#'
	ip -o -4 addr list eth0 | sed -n 1p | awk '{print $4}' | cut -d/ -f1
}

if [[ $(nodetool status | grep "$(_ip_address)") == *"UN"* ]]; then
  if [[ $DEBUG ]]; then
    echo "UN";
  fi
  exit 0;
else
  if [[ $DEBUG ]]; then
    echo "Not Up";
  fi
  exit 1;
fi

