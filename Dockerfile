#Grafana 3.1.1 on wheezy/jessie using node 5.10.1
FROM debian:jessie
MAINTAINER fg2it

ENV PATH=/usr/local/go/bin:$PATH \
    GOPATH=/tmp/graf-build \
    NODEVERSION=5.10.1 \
    PHJSURL=https://github.com/fg2it/phantomjs-on-raspberry/releases/download/v2.1.1-wheezy-jessie/

RUN apt-get update       && \
    apt-get install -y      \
        xz-utils            \
        bzip2               \
        curl                \
        git                 \
        ca-certificates     \
        binutils            \
        libfontconfig1      \
        make                \
        gcc                 \
        libc-dev            \
        g++                 \
        ruby                \
        ruby-dev         && \
    echo "deb http://emdebian.org/tools/debian/ jessie main" >> /etc/apt/sources.list    && \
    curl -sSL http://emdebian.org/tools/debian/emdebian-toolchain-archive.key | apt-key add - && \
    dpkg --add-architecture armhf && \
    apt-get update       && \
    apt-get install -y      \
        crossbuild-essential-armhf && \
    gem install --no-ri --no-rdoc fpm      && \
    curl -sSL https://storage.googleapis.com/golang/go1.7.1.linux-amd64.tar.gz \
      | tar -xz -C /usr/local && \
    curl -sSL https://nodejs.org/dist/v${NODEVERSION}/node-v${NODEVERSION}-linux-x64.tar.xz    \
      | tar -xJ --strip-components=1 -C /usr/local && \
    mkdir -p $GOPATH          && \
    cd $GOPATH                && \
    go get github.com/grafana/grafana  || true && \
    cd $GOPATH/src/github.com/grafana/grafana  && \
    npm install                       && \
    npm config set unsafe-perm true   && \
    npm install -g grunt-cli

COPY crossBuild.go $GOPATH/src/github.com/grafana/grafana

RUN cd $GOPATH/src/github.com/grafana/grafana  && \
    go run crossBuild.go setup        && \
    go run crossBuild.go -goarch=armv7                 \
                         -cgo-enabled=1                \
                         -cc=arm-linux-gnueabihf-gcc   \
                         -cxx=arm-linux-gnueabihf-g++  \
                         build        && \
    grunt release                     && \
    curl -sSL ${PHJSURL}/phantomjs -o /usr/local/bin/phantomjs && \
    cp /usr/local/bin/phantomjs tmp/vendor/phantomjs && \
    go run crossBuild.go -pkg-arch=armhf pkg-deb

CMD ["/bin/bash"]
