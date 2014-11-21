FROM ubuntu:trusty
MAINTAINER Fabio Rehm <fgrehm@gmail.com>

RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main" > /etc/apt/sources.list && \
    echo "deb http://archive.ubuntu.com/ubuntu/ trusty-updates main" >> /etc/apt/sources.list && \
    echo "deb http://security.ubuntu.com/ubuntu trusty-security main" >> /etc/apt/sources.list && \
    echo "deb-src http://archive.ubuntu.com/ubuntu trusty main" >> /etc/apt/sources.list && \
    echo "deb-src http://archive.ubuntu.com/ubuntu/ trusty-updates main" >> /etc/apt/sources.list && \
    echo "deb-src http://security.ubuntu.com/ubuntu trusty-security main" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get -y upgrade && \
    apt-get install -qq \
                    apache2 \
                    logrotate \
                    squid-langpack \
                    ca-certificates \
                    libgssapi-krb5-2 \
                    libltdl7 \
                    libecap2 \
                    libnetfilter-conntrack3 \
                    libssl-dev \
                    curl && \
    apt-get -y build-dep squid3 && \
    apt-get clean


# Install packages
RUN cd /tmp && \
    curl -L http://www.squid-cache.org/Versions/v3/3.4/squid-3.4.9.tar.gz | tar xvz

# Build the squid
RUN cd /tmp/squid-3.4.9 && \
    ./configure --prefix=/usr \
		--enable-ssl \
		--enable-ssl-crtd \
		--enable-inline \
		--enable-async-io=8 \
		--enable-storeio="ufs,aufs,diskd,rock" \
		--enable-removal-policies="lru,heap" \
		--enable-delay-pools \
		--enable-cache-digests \
		--enable-underscores \
		--enable-icap-client \
		--enable-follow-x-forwarded-for \
		--enable-url-rewrite-helpers="fake" \
		--enable-eui \
		--enable-esi \
		--enable-icmp \
		--enable-zph-qos \
		--enable-ecap \
		--disable-translation \
		--with-swapdir=/var/spool/squid3 \
		--with-logdir=/var/log/squid3 \
		--with-pidfile=/var/run/squid3.pid \
		--with-filedescriptors=65536 \
		--with-large-files \
		--with-default-user=proxy \
		--libexecdir=/usr/lib/squid3 \
		--srcdir=. \
		--sysconfdir=/etc/squid3 \
		--mandir=/usr/share/man \
		--localstatedir=/var \
		--datadir=/usr/share/squid3 && \
    make && \
    make install


# Create cache directory
VOLUME /var/cache/squid3

# Initialize dynamic certs directory
RUN /usr/lib/squid3/ssl_crtd -c -s /var/lib/ssl_db
RUN chown -R proxy:proxy /var/lib/ssl_db

# Prepare configs and executable
ADD rewrite_db.txt /etc/squid3/rewrite_db.txt
ADD squid.conf /etc/squid3/squid.conf
ADD openssl.cnf /etc/squid3/openssl.cnf
ADD mk-certs /usr/local/bin/mk-certs
ADD run /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

EXPOSE 3128
CMD ["/usr/local/bin/run"]
