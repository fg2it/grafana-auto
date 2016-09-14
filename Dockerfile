#hand generated :-)
#Grafana 3.1.1 on wheezy/jessie using node 5.10.1
FROM debian:jessie
MAINTAINER fg2it

ENV PATH=/usr/local/go/bin:$PATH \
    GOPATH=/tmp/graf-build \
    GRAFANAVERSION=3.1.1 \
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
    curl -sSL https://storage.googleapis.com/golang/go1.5.2.linux-amd64.tar.gz \
      | tar -xz -C /usr/local && \
    curl -sSL https://nodejs.org/dist/v${NODEVERSION}/node-v${NODEVERSION}-linux-x64.tar.xz    \
      | tar -xJ --strip-components=1 -C /usr/local && \
    mkdir -p $GOPATH          && \
    cd $GOPATH                && \
    go get github.com/grafana/grafana  || true && \
    cd $GOPATH/src/github.com/grafana/grafana  && \
    git checkout v${GRAFANAVERSION}            && \
    go get -v github.com/tools/godep           && \
    CGO_ENABLED=1 CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++ \
      GOOS=linux GOARCH=arm GOARM=7 go get -v github.com/mattn/go-sqlite3 && \
   CGO_ENABLED=1 CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++ \
      GOOS=linux GOARCH=arm GOARM=7 go install -v github.com/mattn/go-sqlite3 && \
    CGO_ENABLED=1 CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++ \
      GOOS=linux GOARCH=arm GOARM=7 $GOPATH/bin/godep restore &&\  
    npm install                       && \
    npm config set unsafe-perm true   && \
    npm install -g grunt-cli

COPY crossBuild.go $GOPATH/src/github.com/grafana/grafana

RUN cd $GOPATH/src/github.com/grafana/grafana  && \
    go run crossBuild.go build        && \
    grunt release                     && \
    curl -sSL ${PHJSURL}/phantomjs -o /usr/local/bin/phantomjs && \
    cp /usr/local/bin/phantomjs tmp/vendor/phantomjs && \
    go run crossBuild.go pkg-deb

CMD ["/bin/bash"]
