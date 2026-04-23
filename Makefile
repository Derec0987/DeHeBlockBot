ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeHeBlockBot
# 🌟 關鍵修正：把所有的 .mm 檔案都加入編譯清單！
DeHeBlockBot_FILES = Tweak.xm BotController.mm Engine.mm ScreenReader.mm TouchSimulator.mm

DeHeBlockBot_CFLAGS = -fobjc-arc -Wno-error
DeHeBlockBot_CXXFLAGS = -std=c++17 -Wno-error
DeHeBlockBot_OBJCXXFLAGS = -std=c++17 -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk