TARGET = iphone:clang:12.1
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppSelector
AppSelector_FILES = Tweak.xm SettingsReader.m
AppSelector_FRAMEWORKS = UIKit AudioToolbox
AppSelector_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSMS Preferences"

SUBPROJECTS += appselectorprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
