FROM redis:5.0

RUN apt-get -y update \
    && apt-get -y install procps net-tools
