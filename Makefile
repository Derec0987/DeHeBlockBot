at > Makefile << 'EOF'
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeHeBlockBot

DeHeBlockBot_FILES = \
    Tweak.xm \
    Engine.mm \
    ScreenReader.mm \
    TouchSimulator.mm \
    BotController.mm

DeHeBlockBot_CFLAGS     = -fobjc-arc
DeHeBlockBot_CCFLAGS    = -fobjc-arc -std=c++17
DeHeBlockBot_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
EOF