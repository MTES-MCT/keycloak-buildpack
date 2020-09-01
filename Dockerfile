FROM scalingo/scalingo-18

ADD . buildpack

ADD .env /env/.env
RUN buildpack/bin/env.sh /env/.env /env
RUN buildpack/bin/compile /build /cache /env
RUN cp -r /build/bin /app/bin
RUN cp -r /build/java /app/java
RUN cp -r /build/keycloak /app/keycloak
RUN cp -r /build/tools /app/tools

EXPOSE 8080
EXPOSE 8443

RUN sed -i "/pipefail/a export PATH=\$PATH:\/app\/java\/bin" "/app/bin/run"

ENTRYPOINT [ "/app/bin/run" ]

CMD [ "-b", "0.0.0.0" ]