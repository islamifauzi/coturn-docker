FROM alpine:3.7

# coturn dependencies
ENV REAL_DEPS="sqlite libevent libressl"
ENV BUILD_DEPS="git shadow pwgen g++ make sqlite-dev libevent-dev libressl-dev linux-headers"
RUN apk update && apk add $REAL_DEPS $BUILD_DEPS

# get the latest (as yet) release
ARG COTURN_VERSION=4.5.0.7
RUN git clone --branch $COTURN_VERSION https://github.com/coturn/coturn.git coturn

# build coturn
WORKDIR /coturn
RUN ./configure && make && make install
WORKDIR /

# user and folders configuration
RUN mkdir /build
COPY scripts/ensure_user_and_group.sh /build/ensure_user_and_group.sh

ARG COTURN_USER=matrix-coturn
ARG COTURN_GROUP=matrix-coturn
RUN /build/ensure_user_and_group.sh $COTURN_USER $COTURN_GROUP

ENV DATA_DIR="/data"
RUN mkdir $DATA_DIR && chmod o+r $DATA_DIR

# create config
COPY scripts/generate_config.sh /build/generate_config.sh
ARG SERVER_NAME
ARG KEY_NAME=matrix-coturn-key.pem
ARG CERT_NAME=matrix-coturn-cert.pem
ENV CONFIG_FILE=coturn.conf
RUN /build/generate_config.sh $SERVER_NAME $DATA_DIR $KEY_NAME $CERT_NAME $CONFIG_FILE

USER $COTURN_USER:$COTURN_GROUP

ENTRYPOINT turnserver -c $DATA_DIR/$CONFIG_FILE
EXPOSE 3478/tcp
EXPOSE 3478/udp
EXPOSE 5349/tcp
EXPOSE 5349/udp
EXPOSE 60000-60015/udp
VOLUME ["$DATA_DIR"]
