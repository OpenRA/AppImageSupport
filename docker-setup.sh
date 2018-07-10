#!/bin/sh

# Add a default user to squash unknown user errors
adduser --uid "${USERID}" hostuser

# Install dependencies
yum -y clean all
yum -y clean expire-cache
yum -y install epel-release
yum -y install gcc gcc-c++ cmake patch openal-soft
yum -y install readline-devel mesa-libGL-devel alsa-lib-devel libGLU-devel libXrender-devel libXrandr-devel libXcursor-devel

# Run the build as the default user so that generated files aren't owned by root
su hostuser -c "./build-libraries.sh"
