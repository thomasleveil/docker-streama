FROM mozart/grails:2.4.4
MAINTAINER Lennart Weller <lhw@ring0.de>

COPY streama /opt/streama
WORKDIR /opt/streama

RUN grails prod refresh-dependencies
RUN grails prod compile

RUN groupadd streama
RUN useradd -s /bin/bash -m -d /opt/streama -g streama streama
RUN apt-get update && apt-get dist-upgrade -y && apt-get install -y mysql-client

RUN chown streama:streama /opt/streama/grails-app/conf/DataSource.groovy

USER streama

ADD start.sh /opt/streama/

EXPOSE 8080
ENTRYPOINT []
CMD ["./start.sh"]
