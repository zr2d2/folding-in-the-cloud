FROM linuxmintd/mint21.2-amd64
USER root
RUN apt update
RUN apt install -y wget
RUN wget https://download.foldingathome.org/releases/public/release/fahclient/debian-testing-64bit/v7.4/fahclient_7.4.4_amd64.deb
RUN dpkg-deb --extract fahclient_7.4.4_amd64.deb fahclient
ENTRYPOINT ["/fahclient/usr/bin/FAHClient"]
