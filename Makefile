cat > Makefile << 'EOF'
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

DeHeBlockBot_CFLAGS   = -fobjc-arc
DeHeBlockBot_CCFLAGS  = -fobjc-arc -std=c++17

DeHeBlockBot_Engine_mm_CFLAGS        = -std=c++17 -fobjc-arc
DeHeBlockBot_ScreenReader_mm_CFLAGS  = -std=c++17 -fobjc-arc
DeHeBlockBot_TouchSimulator_mm_CFLAGS = -std=c++17 -fobjc-arc
DeHeBlockBot_BotController_mm_CFLAGS  = -std=c++17 -fobjc-arc

DeHeBlockBot_FRAMEWORKS = UIKit CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
EOF