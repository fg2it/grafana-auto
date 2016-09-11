#Grafana 3.1.1 on wheezy/jessie using node 5.10.1
#uses phantomjs binary from
#https://github.com/fg2it/phantomjs-on-raspberry/releases/tag/v2.1.1-wheezy-jessie
#and some pre-build binary from a bintray repo
#fpm 1.6.0
#node-sass binding
FROM resin/rpi-raspbian:jessie
MAINTAINER fg2it

ENV PATH=/usr/local/go/bin:$PATH \
    GOPATH=/tmp/graf-build \
    GRAFANAVERSION=3.1.1 \
    NODEVERSION=5.10.1 \
    PHJSURL=https://github.com/fg2it/phantomjs-on-raspberry/releases/download/v2.1.1-wheezy-jessie/

#gcc libc-dev for go-sqlite
RUN echo "deb http://dl.bintray.com/fg2it/deb jessie main" \
      | tee -a /etc/apt/sources.list && \
    apt-get update       && \
    apt-get install -y      \
        curl                \
        git                 \
        ca-certificates     \
        binutils            \
        libfontconfig1      \
        gcc                 \
        libc-dev            \
        rubygem-fpm      && \
    curl -sSL https://github.com/hypriot/golang-armbuilds/releases/download/v1.5.2/go1.5.2.linux-armv7.tar.gz  \
      | tar -xz -C /usr/local && \
    curl -sSL ${PHJSURL}/phantomjs -o /usr/local/bin/phantomjs   && \
    chmod a+x /usr/local/bin/phantomjs && \
    curl -sSL https://nodejs.org/dist/v${NODEVERSION}/node-v${NODEVERSION}-linux-armv7l.tar.xz    \
      | tar -xJ --strip-components=1 -C /usr/local && \
    mkdir -p $GOPATH          && \
    cd $GOPATH                && \
    go get github.com/grafana/grafana  || true && \
    cd $GOPATH/src/github.com/grafana/grafana  && \
    git checkout v${GRAFANAVERSION}            && \
    go run build.go setup     && \
    $GOPATH/bin/godep restore -d && \
    npm install --sass_binary_site=https://dl.bintray.com/fg2it/generic/ && \
    npm install -g grunt-cli  && \
    go run build.go build pkg-deb

CMD ["/bin/bash"]
