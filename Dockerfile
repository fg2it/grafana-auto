#Grafana master on wheezy/jessie using node 5.10.1
FROM debian:jessie
MAINTAINER fg2it

ENV PATH=/usr/local/go/bin:$PATH \
    GOPATH=/tmp/graf-build \
    NODEVERSION=5.10.1 \
    PHJSURL=https://github.com/fg2it/phantomjs-on-raspberry/releases/download/v2.1.1-wheezy-jessie-armv6/

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
    echo "deb http://emdebian.org/tools/debian/ jessie main" >> /etc/apt/sources.list.d/crosstools.list    && \
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
    curl -sSL ${PHJSURL}/phantomjs -o /tmp/phantomjs && \
    chmod a+x /tmp/phantomjs && \
    mkdir -p $GOPATH          && \
    cd $GOPATH                && \
    go get github.com/grafana/grafana  || true && \
    cd $GOPATH/src/github.com/grafana/grafana  && \
    npm install                                && \
    go run build.go setup                      && \
    go run build.go                   \
       -pkg-arch=armhf                \
       -goarch=armv7                  \
       -cgo-enabled=1                 \
       -cc=arm-linux-gnueabihf-gcc    \
       -cxx=arm-linux-gnueabihf-g++   \
       -phjs=/tmp/phantomjs           \
           build                      \
           pkg-deb

CMD ["/bin/bash"]
