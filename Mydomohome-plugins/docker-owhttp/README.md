## docker-owhttp

###How to start
docker run -d -p 8082:80 --device=/dev/bus/usb/004/005:/dev/bus/usb/004/005 zaraki673/docker-owhttp

replace 004/005 with our usb Bus id and Device id:

here my usb Bus Id is 004 and Device Id = 005

When I do "lsusb" on my docker host, I have :

 Bus 004 Device 005: ID 04fa:2490 Dallas Semiconductor DS1490F 2-in-1 Fob, 1-Wire adapter

