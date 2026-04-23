ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeHeBlockBot
DeHeBlockBot_FILES = Tweak.xm BotController.mm Engine.mm ScreenReader.mm TouchSimulator.mm

# 針對 .m (Objective-C)
DeHeBlockBot_CFLAGS = -fobjc-arc -Wno-error
# 針對 .cpp (C++)
DeHeBlockBot_CXXFLAGS = -std=c++17 -Wno-error
# 🌟 針對 .mm (Objective-C++)：這行是解開 C++17 封印的關鍵
DeHeBlockBot_OBJCCFLAGS = -std=c++17 -fobjc-arc -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk