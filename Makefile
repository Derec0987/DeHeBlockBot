ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DeHeBlockBot
DeHeBlockBot_FILES = Tweak.xm
DeHeBlockBot_CFLAGS = -fobjc-arc
DeHeBlockBot_CXXFLAGS = -std=c++17

include $(THEOS_MAKE_PATH)/tweak.mk