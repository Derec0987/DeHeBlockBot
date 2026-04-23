INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeHeBlockBot

DeHeBlockBot_FILES = \
    Tweak.x \
    Engine.mm \
    ScreenReader.mm \
    TouchSimulator.mm \
    BotController.mm

# Tweak.x → 純 ObjC，用 _CFLAGS
DeHeBlockBot_CFLAGS   = -fobjc-arc
# .mm 檔 → ObjC++，用 _CCFLAGS
DeHeBlockBot_CCFLAGS  = -fobjc-arc -std=c++17
DeHeBlockBot_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk