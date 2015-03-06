################################################################################
#
# fischstaebchen
#
################################################################################

FISCHSTAEBCHEN_VERSION         = 0.1.1
#FISCHSTAEBCHEN_LIVEVER_REF     = v$(FISCHSTAEBCHEN_VERSION)
FISCHSTAEBCHEN_LIVEVER_REF     = 9736cc09d6af0001189ddb7e101b47938c19b6e5
FISCHSTAEBCHEN_SOURCE          = fischstaebchen-$(FISCHSTAEBCHEN_LIVEVER_REF).tar.gz
FISCHSTAEBCHEN_SITE            = $(call github,dywsisor,fischstaebchen,$(FISCHSTAEBCHEN_LIVEVER_REF))
FISCHSTAEBCHEN_LICENSE         = MIT
FISCHSTAEBCHEN_LICENSE_FILES   = COPYING LICENSE

ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_OVERLAY),y)
FISCHSTAEBCHEN_DEPENDENCIES += host-python3
endif

# install after busybox, util-linux
ifeq ($(BR2_PACKAGE_BUSYBOX),y)
FISCHSTAEBCHEN_DEPENDENCIES += busybox
endif

ifeq ($(BR2_PACKAGE_UTIL_LINUX),y)
FISCHSTAEBCHEN_DEPENDENCIES += util-linux
endif

FISCHSTAEBCHEN_DATADIR = /usr/share/fischstaebchen

FISCHSTAEBCHEN_MAKEOPTS  =
FISCHSTAEBCHEN_MAKEOPTS += USE_LTO=1
ifeq ($(BR2_GCC_ENABLE_GRAPHITE),y)
FISCHSTAEBCHEN_MAKEOPTS += USE_GRAPHITE=1
else
ifeq ($(BR2_TOOLCHAIN_EXTERNAL_CUSTOM),y)
FISCHSTAEBCHEN_MAKEOPTS += USE_GRAPHITE=1
else
FISCHSTAEBCHEN_MAKEOPTS += USE_GRAPHITE=0
endif
endif
FISCHSTAEBCHEN_MAKEOPTS += $(TARGET_CONFIGURE_OPTS)
FISCHSTAEBCHEN_MAKEOPTS += STATIC=0 NONSHARED=0
FISCHSTAEBCHEN_MAKEOPTS += PREFIX=/usr LIBDIR_NAME=lib

FISCHSTAEBCHEN_INIT_MAKEOPTS  = $(FISCHSTAEBCHEN_MAKEOPTS)
FISCHSTAEBCHEN_INIT_MAKEOPTS += LIBFISCHSTAEBCHEN_VERSIONED=1
FISCHSTAEBCHEN_INIT_MAKEOPTS += PROG_INIT_DEST=fischstaebchen-init

FISCHSTAEBCHEN_OVERLAY_MAKEOPTS  = $(FISCHSTAEBCHEN_MAKEOPTS)
FISCHSTAEBCHEN_OVERLAY_MAKEOPTS += OVERLAY_INITDIR_REL="$(FISCHSTAEBCHEN_DATADIR)"
FISCHSTAEBCHEN_OVERLAY_MAKEOPTS += UDHCPC_SCRIPT_FILE="$(FISCHSTAEBCHEN_DATADIR)/udhcpc.script"

FISCHSTAEBCHEN_INIT_PROGS =

ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_INIT_INIT),y)
FISCHSTAEBCHEN_INIT_PROGS += init
endif

ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_INIT_UNTAR),y)
FISCHSTAEBCHEN_INIT_PROGS += untar
endif

ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_INIT_FILESCAN),y)
FISCHSTAEBCHEN_INIT_PROGS += filescan
endif

ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_INIT_FILESIZE),y)
FISCHSTAEBCHEN_INIT_PROGS += filesize
endif

ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_INIT_ZRAM_TOOLS),y)
FISCHSTAEBCHEN_INIT_PROGS += ztmpfs
endif

ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_INIT_CREATE_USER_TMPDIRS),y)
FISCHSTAEBCHEN_INIT_PROGS += create-user-tmpdirs
endif

# localconfig.h
define FISCHSTAEBCHEN_DO_GEN_BASE_CONFIG_H
	{ \
		printf '#define %s "%s"\n' \
			INITRAMFS_DATADIR '$(FISCHSTAEBCHEN_DATADIR)' && \
		\
		printf '#define DEFAULT_PATH "%s"\n' \
			'$(call qstrip,$(BR2_PACKAGE_FISCHSTAEBCHEN_CFG_DEFAULT_PATH))' && \
		\
		printf '#define ZRAM_DEFAULT_COMPRESSION ZRAM_COMP_%s\n' \
			'$(if $(BR2_PACKAGE_FISCHSTAEBCHEN_ZRAM_COMP_LZ4),LZ4,LZO)' && \
		\
		true; \
	} > $(@D)/localconfig.h

	{ \
		true $(foreach c,\
			ENABLE_BUSYBOX \
			ENABLE_DEVTMPFS \
			ENABLE_MDEV \
			MDEV_LOG \
			MDEV_SEQ \
			ZRAM_CLAIM_CHECK_INITSTATE \
			ZRAM_DISK_ENABLE_BTRFS \
			ZRAM_DISK_ENABLE_EXT2 \
			ZRAM_DISK_ENABLE_EXT2_EXTERN \
			ZRAM_DISK_ENABLE_EXT4 \
			ZRAM_DISK_MAKESYM \
			ZRAM_DISK_PREFER_BTRFS \
			ZRAM_SET_COMPRESSION_AFTER_CLAIM,\
			&& printf '#define %s %s\n' \
				'$(c)' '$(if $(BR2_PACKAGE_FISCHSTAEBCHEN_CFG_$(c)),1,0)' \
		); \
	} >> $(@D)/localconfig.h

	{ \
		true $(foreach g,\
			CDROM DISK TTY,\
			&& printf '#define DEVFS_%s_GID %d\n' \
				'$(g)' '$(call qstrip,$(BR2_PACKAGE_FISCHSTAEBCHEN_DEVFS_$(g)_GID))' \
		); \
	} >> $(@D)/localconfig.h
endef
FISCHSTAEBCHEN_PRE_CONFIGURE_HOOKS += FISCHSTAEBCHEN_DO_GEN_BASE_CONFIG_H

ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_USE_EXTERN_FINDFS),y)
define FISCHSTAEBCHEN_DO_APPEND_CONFIG_EXTERN_FINDFS
	printf '#define FINDFS_EXE "%s"\n' '/sbin/findfs'
endef
FISCHSTAEBCHEN_PRE_CONFIGURE_HOOKS += FISCHSTAEBCHEN_DO_APPEND_CONFIG_EXTERN_FINDFS
endif

# metash_vdef.local
define FISCHSTAEBCHEN_DO_GEN_BASE_METASH_VDEF
	{ \
		printf '%s\n' '!stripspace' && \
		printf '%s\n' '!noformat' && \
		\
		printf '%s=%s\n' DEFAULT_INITRAMFS_DATADIR '$(FISCHSTAEBCHEN_DATADIR)' && \
		\
		printf '%s=%s\n' PROG_UNTAR \
			'$(if $(BR2_PACKAGE_FISCHSTAEBCHEN_INIT_UNTAR),/usr/bin/untar,false)' && \
		\
		printf '%s=%s\n' PROG_FILESCAN \
			'$(if $(BR2_PACKAGE_FISCHSTAEBCHEN_INIT_FILESCAN),/usr/bin/filescan,false)' && \
		\
		printf '%s=%s\n' PROG_FILESIZE \
			'$(if $(BR2_PACKAGE_FISCHSTAEBCHEN_INIT_FILESIZE),/usr/bin/filesize,false)' && \
		\
		printf '%s=%s\n' HAVE_IUCODE_TOOL \
			'$(if $(BR2_PACKAGE_IUCODE_TOOL),1,0)' && \
		\
		printf '%s=%s\n' OFFENSIVE \
			'$(if $(BR2_PACKAGE_FISCHSTAEBCHEN_OVERLAY_CFG_OFFENSIVE),1,0)' && \
		\
		printf '%s=%s\n' WGET_OPTS \
			'$(if $(BR2_PACKAGE_WGET),--no-check-certificate --quiet --show-progress,)' && \
		\
		printf '%s=%s\n' WGET_PROG \
			'$(if $(BR2_PACKAGE_WGET),/usr/bin/wget,wget)' && \
		\
		true; \
	} > $(@D)/metash_vdef.local
endef
FISCHSTAEBCHEN_PRE_CONFIGURE_HOOKS += FISCHSTAEBCHEN_DO_GEN_BASE_METASH_VDEF


ifeq ($(BR2_PACKAGE_BUSYBOX),y)
define FISCHSTAEBCHEN_DO_APPEND_METASH_VDEF_BUSYBOX
	{ \
		printf '%s=%s\n' BUSYBOX    '/bin/busybox'         && \
		printf '%s=%s\n' BB         '$${BB:-/bin/busybox}' && \
		printf '%s=%s\n' BB_APPLET  '$${BB:-/bin/busybox}' ; \
	} >> $(@D)/metash_vdef.local
endef
else
define FISCHSTAEBCHEN_DO_APPEND_METASH_VDEF_BUSYBOX
	{ \
		printf '%s=\n' BUSYBOX    && \
		printf '%s=\n' BB         && \
		printf '%s=\n' BB_APPLET  ; \
	} >> $(@D)/metash_vdef.local
endef
endif
FISCHSTAEBCHEN_PRE_CONFIGURE_HOOKS += FISCHSTAEBCHEN_DO_APPEND_METASH_VDEF_BUSYBOX

ifeq ($(BR2_PACKAGE_COREUTILS),y)
define FISCHSTAEBCHEN_DO_APPEND_METASH_VDEF_COREUTILS
	{ \
		printf '%s=%d\n' HAVE_COREUTILS  1 && \
		printf '%s=%s\n' PROG_REALPATH   '/usr/bin/realpath' ; \
	} >> $(@D)/metash_vdef.local
endef
else
define FISCHSTAEBCHEN_DO_APPEND_METASH_VDEF_COREUTILS
	printf '%s=%d\n' HAVE_COREUTILS 0 >> $(@D)/metash_vdef.local
endef
endif
FISCHSTAEBCHEN_PRE_CONFIGURE_HOOKS += FISCHSTAEBCHEN_DO_APPEND_METASH_VDEF_COREUTILS

# overlays.list
ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_OVERLAY),y)
# at least one overlay is always selected
define FISCHSTAEBCHEN_DO_GEN_OVERLAYS_LIST
	printf '%s\n' \
		'\
		$(foreach upname,\
			BASE \
			DOTFILES \
			MISC \
			NEWROOT_HOOKS \
			PHASEOUT \
			SEPARATE_USR \
			SQUASHED_ROOTFS \
			STAGEDIVE \
			STAGEDIVE_BOOTSTRAP_ARCH \
			STAGEDIVE_BOOTSTRAP_GENTOO \
			TELINIT \
			UNION_MOUNT \
			UNION_MOUNT_BASE, \
			$(if $(BR2_PACKAGE_FISCHSTAEBCHEN_OVERLAY_$(upname)),$(upname)) \
		)\
		$(call qstrip,$(BR2_PACKAGE_FISCHSTAEBCHEN_OVERLAY_CUSTOM_LIST)) \
		' | tr '[:upper:]' '[:lower:]' | \
			xargs -n 1 printf '%s\n' | sort -u > $(@D)/overlays.list

	test -s '$(@D)/overlays.list'
endef
FISCHSTAEBCHEN_PRE_CONFIGURE_HOOKS += FISCHSTAEBCHEN_DO_GEN_OVERLAYS_LIST

ifeq ($(BR2_PACKAGE_BUSYBOX),y)
define FISCHSTAEBCHEN_DO_APPEND_OVERLAYS_LIST_BUSYBOX
	printf '%s\n' udhcpc >> $(@D)/overlays.list
endef
FISCHSTAEBCHEN_PRE_CONFIGURE_HOOKS += FISCHSTAEBCHEN_DO_APPEND_OVERLAYS_LIST_BUSYBOX
endif

ifeq ($(BR2_PACKAGE_DROPBEAR),y)
define FISCHSTAEBCHEN_DO_APPEND_OVERLAYS_LIST_DROPBEAR
	printf '%s\n' dropbear >> $(@D)/overlays.list
endef
FISCHSTAEBCHEN_PRE_CONFIGURE_HOOKS += FISCHSTAEBCHEN_DO_APPEND_OVERLAYS_LIST_DROPBEAR
endif

else
define FISCHSTAEBCHEN_DO_GEN_EMPTY_OVERLAYS_LIST
	: > '$(@D)/overlays.list'
endef
FISCHSTAEBCHEN_PRE_CONFIGURE_HOOKS += FISCHSTAEBCHEN_DO_GEN_EMPTY_OVERLAYS_LIST
endif

ifneq ($(FISCHSTAEBCHEN_INIT_PROGS),)
define FISCHSTAEBCHEN_DO_BUILD_INIT
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/init $(FISCHSTAEBCHEN_INIT_MAKEOPTS) \
		LOCALCONFIG=$(@D)/localconfig.h \
		libfischstaebchen $(FISCHSTAEBCHEN_INIT_PROGS)
endef
FISCHSTAEBCHEN_POST_BUILD_HOOKS += FISCHSTAEBCHEN_DO_BUILD_INIT

define FISCHSTAEBCHEN_DO_INSTALL_INIT
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D)/init $(FISCHSTAEBCHEN_INIT_MAKEOPTS) \
		LOCALCONFIG=$(@D)/localconfig.h \
		DESTDIR=$(TARGET_DIR) \
		$(addprefix install-,libfischstaebchen $(FISCHSTAEBCHEN_INIT_PROGS))
endef
FISCHSTAEBCHEN_POST_INSTALL_TARGET_HOOKS += FISCHSTAEBCHEN_DO_INSTALL_INIT

define FISCHSTAEBCHEN_DO_SETUP_LINUXRC
	test -f '$(TARGET_DIR)/fischstaebchen-init'

	true $(foreach sym,$(addprefix $(TARGET_DIR)/,init rdinit linuxrc),\
		&& { test ! -h '$(sym)' && test ! -e '$(sym)' || rm -- '$(sym)'; } \
		&& ln -s -- fischstaebchen-init '$(sym)')
endef
TARGET_FINALIZE_HOOKS += FISCHSTAEBCHEN_DO_SETUP_LINUXRC

define FISCHSTAEBCHEN_DEVICES
	/dev/console c 0622 0 0 5 1 - - -
endef

endif

ifeq ($(BR2_PACKAGE_FISCHSTAEBCHEN_OVERLAY),y)

define FISCHSTAEBCHEN_DO_BUILD_OVERLAY
	$(TARGET_MAKE_ENV) $(MAKE) -C '$(@D)/overlay' $(FISCHSTAEBCHEN_OVERLAY_MAKEOPTS) \
		OVERLAYS='$(shell cat $(@D)/overlays.list)' \
		OVERLAY_DEFAULTS_FILE='$(@D)/metash_vdef.local' \
		overlay
endef
FISCHSTAEBCHEN_POST_BUILD_HOOKS += FISCHSTAEBCHEN_DO_BUILD_OVERLAY

define FISCHSTAEBCHEN_DO_INSTALL_OVERLAY
	$(TARGET_MAKE_ENV) $(MAKE) -C '$(@D)/overlay' $(FISCHSTAEBCHEN_OVERLAY_MAKEOPTS) \
		OVERLAYS='$(shell cat $(@D)/overlays.list)' \
		OVERLAY_DEFAULTS_FILE='$(@D)/metash_vdef.local' \
		DESTDIR='$(TARGET_DIR)' \
		install
endef
FISCHSTAEBCHEN_POST_INSTALL_TARGET_HOOKS += FISCHSTAEBCHEN_DO_INSTALL_OVERLAY

endif # BR2_PACKAGE_FISCHSTAEBCHEN_OVERLAY


$(eval $(generic-package))
