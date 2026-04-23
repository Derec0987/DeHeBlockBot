INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeHeBlockBot
DeHeBlockBot_FILES = Tweak.x
DeHeBlockBot_CFLAGS = -fobjc-arc 
DeHeBlockBot_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
