#################################################################################
#
# diskid
#
#################################################################################

DISKID_VERSION       = 6d49c37ec056fe430cbc7fce83cf376e923fc9c8
DISKID_SITE          = $(call github,dywisor,diskid,$(DISKID_VERSION))
DISKID_LICENSE       = LGPLv2.1+ GPLv2 GPLv2+
DISKID_LICENSE_FILES = COPYING

DISKID_EXE = /sbin/diskid

define DISKID_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C '$(@D)' \
		$(TARGET_CONFIGURE_OPTS) \
		MINIMAL=1 X_DISKID=$(DISKID_EXE) \
		diskid
endef

define DISKID_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 -- $(@D)/diskid $(TARGET_DIR:/=)$(DISKID_EXE)
endef

$(eval $(generic-package))
