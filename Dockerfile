FROM ubuntu:22.04
USER root
RUN apt-get update && apt-get install --no-install-recommends -y wget ca-certificates \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
RUN wget https://download.foldingathome.org/releases/public/release/fahclient/debian-testing-64bit/v7.4/fahclient_7.4.4_amd64.deb
RUN dpkg-deb --extract fahclient_7.4.4_amd64.deb fahclient
ENTRYPOINT ["/fahclient/usr/bin/FAHClient"]