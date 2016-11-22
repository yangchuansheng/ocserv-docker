FROM ubuntu:trusty
MAINTAINER Wyatt Pan <wppurking@gmail.com>

ADD ./certs /opt/certs
ADD ./bin /usr/local/bin
ADD dnsmasq.conf /usr/local/etc/dnsmasq.conf
RUN chmod a+x /usr/local/bin/*
WORKDIR /etc/ocserv

# china timezone
RUN echo "Asia/Shanghai" > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

# install compiler, dependencies, tools , dnsmasq
RUN apt-get update && apt-get install -y \
    build-essential wget xz-utils libgnutls28-dev \
    libev-dev libwrap0-dev libpam0g-dev libseccomp-dev libreadline-dev \
    libnl-route-3-dev libkrb5-dev liboath-dev libprotobuf-c0-dev libtalloc-dev \
    libhttp-parser-dev libpcl1-dev libopts25-dev autogen pkg-config nettle-dev \
    protobuf-c-compiler gnutls-bin gperf liblockfile-bin nuttcp lcov iptables \
    unzip dnsmasq \
    && rm -rf /var/lib/apt/lists/*

# configuration dnsmasq
RUN mkdir -p /temp && cd /temp \
    && wget https://github.com/felixonmars/dnsmasq-china-list/archive/master.zip \
    && unzip master.zip \
    && cd dnsmasq-china-list-master \
    && cp *.conf /etc/dnsmasq.d/ \
    && cd / && rm -rf /temp

# configuration lz4
RUN mkdir -p /temp && cd /temp \
    && wget https://github.com/lz4/lz4/archive/v1.7.4.tar.gz \
    && tar xvf v1.7.4.tar.gz \
    && cd lz4-1.7.4 \
    && make install \
    && ln -sf /usr/local/lib/liblz4.* /usr/lib/ \
    && cd / && rm -rf /temp

# configuration radcli
RUN mkdir -p /temp && cd /temp \
    && wget https://github.com/radcli/radcli/releases/latest -O radcli.html \
    && export radcli_version=$(cat radcli.html | grep -m 1 -o '[0-9]\.[0-9]\.[0-9]') \
    && wget https://github.com/radcli/radcli/releases/download/$radcli_version/radcli-$radcli_version.tar.gz \
    && tar xzf radcli-$radcli_version.tar.gz \
    && cd radcli-$radcli_version \
    && ./configure --prefix=/usr --sysconfdir=/etc --enable-legacy-compat \
    && make && make install \
    && cd / && rm -rf /temp

# configuration ocserv
RUN mkdir -p /temp && cd /temp \
    && wget http://www.infradead.org/ocserv/download.html \
    && export ocserv_version=$(cat download.html | grep -o '[0-9]*\.[0-9]*\.[0-9]*') \
    && wget ftp://ftp.infradead.org/pub/ocserv/ocserv-$ocserv_version.tar.xz \
    && tar xvf ocserv-$ocserv_version.tar.xz \
    && cd ocserv-$ocserv_version \
    && ./configure --prefix=/usr --sysconfdir=/etc --with-local-talloc \
    && make && make install \
    && cd / && rm -rf /temp

RUN cd /opt/certs && ls \
    && ca_cn=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1) && bash -c "sed -i 's/Your desired authority name/$ca_cn/g' /opt/certs/ca-tmp" \
    && ca_org=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1) && bash -c "sed -i 's/Your desired orgnization name/$ca_org/
