FROM oraclelinux:9-slim

RUN set -eux; \
	key='BCA4 3417 C3B4 85DD 128E C6D4 B7B3 B788 A8D3 785C'; \
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key"; \
	gpg --batch --export --armor "$key" > /etc/pki/rpm-gpg/RPM-GPG-KEY-mysql; \
	rm -rf "$GNUPGHOME"

ENV MYSQL_VERSION 8.4.1-1.el9

RUN set -eu; \
	{ \
		echo '[mysql-community-client]'; \
		echo 'name=MySQL Community Client'; \
		echo 'baseurl=https://repo.mysql.com/yum/mysql-8.4-community/el/9/$basearch/'; \
		echo 'enabled=1'; \
		echo 'gpgcheck=1'; \
		echo 'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-mysql'; \
		echo 'module_hotfixes=true'; \
	} | tee /etc/yum.repos.d/mysql-community-client.repo

ENV MYSQL_SHELL_VERSION 8.4.1-1.el9
RUN set -eux; \
	microdnf install -y \
		rsync \
		findutils \
        glibc-langpack-en \
		"mysql-community-client-$MYSQL_SHELL_VERSION" \
	; \
	microdnf clean all

CMD ["/bin/sh"]