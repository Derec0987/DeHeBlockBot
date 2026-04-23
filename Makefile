ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeHeBlockBot
DeHeBlockBot_FILES = Tweak.xm
# 關閉嚴格的警告轉錯誤機制，並強制使用 C++17
DeHeBlockBot_CFLAGS = -fobjc-arc -Wno-error
DeHeBlockBot_CXXFLAGS = -std=c++17 -Wno-error
DeHeBlockBot_OBJCXXFLAGS = -std=c++17 -Wno-error

include $(THEOS_MAKE_PATH)/tweak.mk