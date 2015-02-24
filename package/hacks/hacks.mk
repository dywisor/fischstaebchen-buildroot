################################################################################
#
# hacks
#
################################################################################

HACKS_VERSION = 0.1
HACKS_SOURCE  =
HACKS_SITE    =
HACKS_LICENSE = GPLv2+

ifeq ($(BR2_PACKAGE_BUSYBOX),y)
HACKS_DEPENDENCIES += busybox
endif

ifeq ($(BR2_PACKAGE_UTIL_LINUX),y)
HACKS_DEPENDENCIES += util-linux
endif

ifeq ($(BR2_PACKAGE_COREUTILS),y)
HACKS_DEPENDENCIES += coreutils
endif

ifeq ($(BR2_PACKAGE_LZ4),y)
HACKS_DEPENDENCIES += lz4
endif

ifeq ($(BR2_PACKAGE_E2FSPROGS),y)
HACKS_DEPENDENCIES += e2fsprogs
endif


define HACKS_EXTRACT_CMDS
	mkdir -p -- $(@D)
endef


ifeq ($(BR2_PACKAGE_HACKS_DROP_BUSYBOX_SYMLINKS),y)
define HACKS_DO_DROP_BUSYBOX_SYMLINKS
	find -P \
		$(addprefix $(TARGET_DIR)/,bin sbin usr/bin usr/sbin) \
		-type l -not -name sh | \
			xargs -r -n 1 -I '{l}' $(or $(SHELL),sh) -c \
				't="$$(readlink -- "{l}")" && [ -n "$${t}" ] || exit 9; \
				case "$${t}" in \
					busybox|*/busybox) rm -v -- "{l}" || exit ;; \
				esac;'
endef

HACKS_POST_INSTALL_TARGET_HOOKS += HACKS_DO_DROP_BUSYBOX_SYMLINKS
endif

ifeq ($(BR2_PACKAGE_HACKS_INITRAMFS_PURGE),y)
define HACKS_DO_INITRAMFS_PURGE
	rm -rf -- $(addprefix $(TARGET_DIR)/etc/,network init.d)
	rm -f  -- $(addprefix $(TARGET_DIR)/etc/,random-seed mtab resolv.conf)

	rm -rf -- $(addprefix $(TARGET_DIR)/,\
		home var/www media mnt usr/share/udhcpc)

	test ! -d '$(TARGET_DIR)/root' || \
	find '$(TARGET_DIR)/root/' -name '.bash*' -delete

	set -e; for f in '$(TARGET_DIR)/usr/lib/libstdc++.so.'*'-gdb.py'; do \
		if test -h "$${f}" || test -f "$${f}"; then \
			rm -v -- "$${f}" || exit; \
		fi; \
	done

	sed -r -e '/^(ftp|sys|www-data)[:]/d' -i '$(TARGET_DIR)/etc/passwd'
	sed -r -e '/^(ftp|sys|www-data)[:]/d' -i '$(TARGET_DIR)/etc/group'
endef

TARGET_FINALIZE_HOOKS += HACKS_DO_INITRAMFS_PURGE
endif

ifeq ($(BR2_PACKAGE_HACKS_UTIL_LINUX_DOWNSIZE),y)
define HACKS_DO_UTIL_LINUX_DOWNSIZE
	for f in \
		$(addprefix $(TARGET_DIR)/,\
			$(addprefix bin/,dmesg findmnt lsblk) \
			$(addprefix sbin/,\
				blkdiscard blockdev chcpu ctrlaltdel \
				fdisk fsfreeze fstrim losetup mkswap sfdisk \
				swaplabel swapoff swapon wipefs \
			) \
			$(addprefix usr/bin/,\
				cal col colcrt colrm column envsubst flock \
				getopt hexdump \
				i386 x86_64 setarch linux32 linux64 uname26 \
				ipcmk ipcrm ipcs isosize logger look \
				lscpu lslocks lslogins mcookie namei \
				prlimit renice rev script scriptreplay \
				setsid tailf whereis \
			) \
			$(addprefix usr/sbin/,ldattach readprofile rtcwake) \
		) \
	; do \
		if test -e "$${f}" || test -h "$${f}"; then \
			rm -v -- "$${f}" || exit; \
		fi; \
	done;
endef

HACKS_POST_INSTALL_TARGET_HOOKS += HACKS_DO_UTIL_LINUX_DOWNSIZE
endif

ifeq ($(BR2_PACKAGE_HACKS_MISC_DOWNSIZE),y)
define HACKS_DO_MISC_DOWNSIZE
	for f in \
		$(addprefix $(TARGET_DIR)/,\
			$(addprefix bin/,) \
			$(addprefix sbin/,) \
			$(addprefix usr/bin/,lz4c) \
			$(addprefix usr/sbin/,) \
		) \
	; do \
		if test -e "$${f}" || test -h "$${f}"; then \
			rm -v -- "$${f}" || exit; \
		fi; \
	done;

	if \
		test ! -h '$(TARGET_DIR)/sbin' && \
		test -f '$(TARGET_DIR)/sbin/findfs' && \
		test ! -h '$(TARGET_DIR)/sbin/findfs' && \
		test -f '$(TARGET_DIR)/usr/sbin/findfs'; \
	then \
		rm -v -- '$(TARGET_DIR)/usr/sbin/findfs' || exit; \
	fi;
endef

HACKS_POST_INSTALL_TARGET_HOOKS += HACKS_DO_MISC_DOWNSIZE

endif

$(eval $(generic-package))
