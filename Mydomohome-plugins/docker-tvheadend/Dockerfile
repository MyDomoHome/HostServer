FROM phusion/baseimage:0.9.18
MAINTAINER Kevin Larsonneur <klarsonneur@gmail.com> #Maintainer source tobbenb <torbjornbrekke@gmail.com>

# Set correct environment variables.
ENV HOME="/root" DEBIAN_FRONTEND="noninteractive"

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]
ADD ./files/ /tmp/
RUN chmod +x /tmp/install/install.sh && sleep 1 && /tmp/install/install.sh && rm -r /tmp/install

EXPOSE 9981 9982

VOLUME /config \
       /recordings \
	   /data
