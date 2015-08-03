FROM mozart/grails
MAINTAINER Lennart Weller <lhw@ring0.de>

COPY streama/ /opt
WORKDIR /opt/streama

RUN grails refresh-dependencies

CMD ["run-app"]
