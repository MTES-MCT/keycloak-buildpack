FROM scalingo/scalingo-20

ADD . buildpack

ADD .env /env/.env
RUN buildpack/bin/env.sh /env/.env /env
RUN buildpack/bin/compile /build /cache /env
RUN rm -rf /app/java
RUN cp -rf /build/java /app/java
RUN rm -rf /app/keycloak
RUN cp -rf /build/keycloak /app/keycloak

EXPOSE 8080
EXPOSE 8443

RUN sed -i "/esac/a export PATH=\$PATH:\/app\/java\/bin" "/app/keycloak/bin/kc.sh"

ENTRYPOINT [ "/app/keycloak/bin/kc.sh", "start"]