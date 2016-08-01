FROM debian
MAINTAINER Kevin Larsonneur <klarsonneur@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update

RUN apt-get -y install owhttpd usbutils supervisor

ADD supervisor.owhttpd.conf /etc/supervisor/conf.d/owhttpd.conf


EXPOSE 80
CMD ["supervisord", "-n"]