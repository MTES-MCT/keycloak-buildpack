FROM scalingo/scalingo-18

ENV JBOSS_HOME /opt/jboss/keycloak
ENV LANG en_US.UTF-8

ADD . buildpack

RUN chmod +x buildpack/bin/compile
RUN buildpack/bin/compile

EXPOSE 8080
EXPOSE 8443

RUN sed -i "/pipefail/a export PATH=\$PATH:\/opt\/java\/bin" "bin/run"

ENTRYPOINT [ "bin/run" ]

CMD [ "-b", "0.0.0.0" ]