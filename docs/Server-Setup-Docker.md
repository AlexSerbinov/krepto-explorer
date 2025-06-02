### Setup of https://kreptoexplorer.org on Ubuntu 20.04

	# update and install packages
	apt update
	apt upgrade
	apt install docker.io
	
	# get source, npm install
	git clone https://github.com/janoside/krepto-rpc-explorer.git
	cd krepto-rpc-explorer
	
	# build docker image
	docker build -t krepto-rpc-explorer .

	# run docker image: detached mode, share port 3002, sharing config dir, from the "krepto-rpc-explorer" image made above
	docker run --name=krepto-rpc-explorer -d -v /host-os/env-dir:/container/env-dir --network="host" krepto-rpc-explorer
	
