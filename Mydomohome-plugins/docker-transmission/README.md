docker-transmission
===================

Transmission Daemon Docker Container

Download in /local/dir
Don't forget to create incomplete dir in /local/dir for tempory file

Application container, don't forget to specify a password for `transmission` account and local directory for the downloads:

    docker run -p 12345:12345 -p 12345:12345/udp -p 9091:9091 -e ADMIN_PASS=password -v /local/dir:/var/lib/transmission-daemon/downloads --name APP zaraki673/docker-transmission

