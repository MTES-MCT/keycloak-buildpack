FROM scalingo/scalingo-18

ADD . buildpack

ADD .env /env/.env
RUN buildpack/bin/env.sh /env/.env /env
RUN buildpack/bin/compile /build /cache /env
RUN rm -rf /app/bin
RUN cp -rf /build/bin /app/bin
RUN rm -rf /app/java
RUN cp -rf /build/java /app/java
RUN rm -rf /app/keycloak
RUN cp -rf /build/keycloak /app/keycloak
RUN rm -rf /app/tools
RUN cp -rf /build/tools /app/tools

EXPOSE 8080
EXPOSE 8443

RUN sed -i "/pipefail/a export PATH=\$PATH:\/app\/java\/bin" "/app/bin/run"

ENTRYPOINT [ "/app/bin/run" ]

CMD [ "-b", "0.0.0.0" ]