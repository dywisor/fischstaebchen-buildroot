################################################################################
#
# apt-cacher-ng
#
################################################################################

APT_CACHER_NG_VERSION = 0.8.0
APT_CACHER_NG_SOURCE = apt-cacher-ng_$(APT_CACHER_NG_VERSION).orig.tar.xz
APT_CACHER_NG_SITE = http://ftp.us.debian.org/debian/pool/main/a/apt-cacher-ng/
APT_CACHER_NG_LICENSE = BSD-4 ZLIB public-domain
APT_CACHER_NG_LICENSE_FILES = COPYING

APT_CACHER_NG_MAKE_OPTS += apt-cacher-ng
APT_CACHER_NG_MAKE_OPTS += DEBUG=$(BR2_ENABLE_DEBUG)

APT_CACHER_NG_CONF_OPTS += -DHAVE_LIBWRAP=no
APT_CACHER_NG_CONF_OPTS += -DPTHREAD_COND_TIMEDWAIT_TIME_RANGE_OK=yes


ifeq ($(BR2_PACKAGE_APT_CACHER_NG_ACNGFS),y)
APT_CACHER_NG_MAKE_OPTS += acngfs
APT_CACHER_NG_DEPENDENCIES += libfuse
APT_CACHER_NG_CONF_OPTS += -DHAVE_FUSE_25=yes
else
APT_CACHER_NG_CONF_OPTS += -DHAVE_FUSE_25=no
endif

ifeq ($(BR2_PACKAGE_ZLIB),y)
APT_CACHER_NG_DEPENDENCIES += zlib
endif

ifeq ($(BR2_PACKAGE_XZ),y)
APT_CACHER_NG_DEPENDENCIES += xz
endif

ifeq ($(BR2_PACKAGE_BZIP2),y)
APT_CACHER_NG_DEPENDENCIES += bzip2
endif

ifeq ($(BR2_PACKAGE_OPENSSL),y)
APT_CACHER_NG_DEPENDENCIES += openssl
endif

define APT_CACHER_NG_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 -- \
		$(APT_CACHER_NG_BUILDDIR)/apt-cacher-ng \
		$(TARGET_DIR)/usr/sbin/apt-cacher-ng

	$(INSTALL) -d -m 0755 -- $(TARGET_DIR)/etc/apt-cacher-ng

	$(INSTALL) -m 0644 -- $(@D)/conf/acng.conf \
		$(TARGET_DIR)/etc/apt-cacher-ng/apt-cacher-ng.conf

	find $(@D)/conf/ -type f -not -name 'acng.conf' \
		-exec $(INSTALL) -m 0644 -t '$(TARGET_DIR)/etc/apt-cacher-ng' '{}' +
endef

ifeq ($(BR2_PACKAGE_AVAHI_DAEMON),y)
define APT_CACHER_NG_DO_INSTALL_AVAHI
	$(INSTALL) -d -m 0644 \
		$(@D)/contrib/apt-cacher-ng.service \
		$(TARGET_DIR)/etc/avahi/services/apt-cacher-ng.service
endef
APT_CACHER_NG_POST_INSTALL_TARGET_HOOKS += APT_CACHER_NG_DO_INSTALL_AVAHI
endif

define APT_CACHER_NG_INSTALL_INIT_SYSTEMD
	$(INSTALL) -d -m 0644 -- \
		$(@D)/systemd/apt-cacher-ng.conf \
		$(TARGET_DIR)/usr/lib/tmpfiles.d/apt-cacher-ng.conf

	$(INSTALL) -d -m 0644 -- \
		$(@D)/systemd/apt-cacher-ng.service \
		$(TARGET_DIR)/lib/systemd/system/apt-cacher-ng.service

	$(INSTALL) -D -m 0755 \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants

	ln -f -s -- \
		/lib/systemd/system/apt-cacher-ng.service \
		$(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/apt-cacher-ng.service
endef

define APT_CACHER_NG_INSTALL_INIT_SYSV
	$(INSTALL) -d -m 0755 \
		$(BR2_EXTERNAL)/package/apt-cacher-ng/apt-cacher-ng.sysv \
		$(TARGET_DIR)/etc/init.d/S70apt-cacher-ng
endef

ifeq ($(BR2_PACKAGE_APT_CACHER_NG_ACNGFS),y)
define APT_CACHER_NG_DO_INSTALL_ACNGFS
	$(INSTALL) -d -m 0755 -- \
		$(APT_CACHER_NG_BUILDDIR)/acngfs $(TARGET_DIR)/usr/bin/acngfs
endef
APT_CACHER_NG_POST_INSTALL_TARGET_HOOKS += APT_CACHER_NG_DO_INSTALL_ACNGFS
endif

define APT_CACHER_NG_USERS
	apt-cacher-ng -1 apt-cacher-ng -1 * - - - apt-cacher-ng
endef

$(eval $(cmake-package))

## insists on building in build/
APT_CACHER_NG_BUILDDIR = $(APT_CACHER_NG_SRCDIR)/build

## need to create build/
define APT_CACHER_NG_DO_MKDIR_BUILD
	mkdir -p -- $(APT_CACHER_NG_BUILDDIR)
	touch -- $(APT_CACHER_NG_BUILDDIR)/.dir-stamp
endef
APT_CACHER_NG_POST_EXTRACT_HOOKS += APT_CACHER_NG_DO_MKDIR_BUILD

## apt-cacher-ng's Makefile logic wants this file
define APT_CACHER_NG_DO_CREATE_CONFIG_FLAGFILE
	touch -- $(APT_CACHER_NG_BUILDDIR)/.config-stamp
endef
APT_CACHER_NG_POST_CONFIGURE_HOOKS += APT_CACHER_NG_DO_CREATE_CONFIG_FLAGFILE
