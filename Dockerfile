FROM scalingo/scalingo-22
ADD . buildpack

ADD .env /env/.env
RUN buildpack/bin/env.sh /env/.env /env
RUN buildpack/bin/compile /build /cache /env
RUN rm -rf /app/java
RUN cp -rf /build/java /app/java
RUN rm -rf /app/keycloak
RUN cp -rf /build/keycloak /app/keycloak
RUN /app/java/bin/keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore /app/keycloak/conf/server.keystore
EXPOSE 8080
EXPOSE 8443

RUN sed -i "/esac/a export PATH=\$PATH:\/app\/java\/bin" "/app/keycloak/bin/kc.sh"

ENTRYPOINT [ "/app/keycloak/bin/kc.sh", "--verbose",  "start" ]