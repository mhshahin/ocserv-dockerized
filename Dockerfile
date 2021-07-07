FROM alpine:3.10

MAINTAINER Mohammad Shahin

ENV OCSERV_VER="0.12.4"

RUN apk add -U curl g++ gnutls-dev gpgme libev-dev gnutls-dev \
	libseccomp-dev iptables tini \
    libnl3-dev linux-headers \
    linux-pam-dev lz4-dev make readline-dev xz \
	&& set -x \
	&& curl -LO ftp://ftp.infradead.org/pub/ocserv/ocserv-${OCSERV_VER}.tar.xz \
	&& mkdir -p /usr/src/ocserv \
	&& tar -xJf ocserv-${OCSERV_VER}.tar.xz -C /usr/src/ocserv --strip-components=1 \
	&& rm ocserv-${OCSERV_VER}.tar.xz* \
	&& cd /usr/src/ocserv \
	&& ./configure \
	&& make \
	&& make install \
	&& mkdir -p /etc/ocserv \
	&& cp /usr/src/ocserv/doc/sample.config /etc/ocserv/ocserv.conf \
	&& cd / \
	&& rm -fr /usr/src/ocserv \
	&& rm -rf /var/cache/apk/*

# Setup config
RUN set -x \
	&& sed -i 's/\.\/sample\.passwd/\/etc\/ocserv\/ocpasswd/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/\.\.\/tests/\/etc\/ocserv/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/#\(compression.*\)/\1/' /etc/ocserv/ocserv.conf \
	&& sed -i '/^ipv4-network = /{s/192.168.1.0/10.10.20.0/}' /etc/ocserv/ocserv.conf \
	&& sed -i 's/192.168.1.2/1.1.1.1/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^route/#route/' /etc/ocserv/ocserv.conf \
	&& sed -i 's/^no-route/#no-route/' /etc/ocserv/ocserv.conf \
	&& sed -i '/\[vhost:www.example.com\]/,$d' /etc/ocserv/ocserv.conf \
	&& mkdir -p /etc/ocserv/certs

WORKDIR /etc/ocserv

COPY certs/server-cert.pem /etc/ocserv/certs/server-cert.pem

COPY certs/server-key.pem /etc/ocserv/certs/server-key.pem

COPY docker-entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 443
CMD ["ocserv", "-c", "/etc/ocserv/ocserv.conf", "-f"]
