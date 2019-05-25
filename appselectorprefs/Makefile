TARGET = iphone:clang:12.1
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = appselectorprefs
appselectorprefs_FILES = APPRootListController.m
appselectorprefs_INSTALL_PATH = /Library/PreferenceBundles
appselectorprefs_FRAMEWORKS = UIKit
appselectorprefs_PRIVATE_FRAMEWORKS = Preferences

appselectorprefs_EXTRA_FRAMEWORKS = Cephei CepheiPrefs

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/appselectorprefs.plist$(ECHO_END)
