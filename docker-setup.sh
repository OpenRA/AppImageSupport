#!/bin/sh


# Install dependencies
apt-get update
#apt-get -y install cmake patch
apt-get -y install curl gcc g++ make patch libopenal1 libncurses-dev libreadline-dev libgl1-mesa-dev libglu1-mesa-dev libx11-dev libxcursor-dev libxext-dev libxi-dev libxinerama-dev libxrandr-dev libxss-dev libxt-dev

# Add a default user to squash unknown user errors
useradd --uid "${USERID}" hostuser

# Run the build as the default user so that generated files aren't owned by root
su hostuser -c "./build-libraries.sh"
