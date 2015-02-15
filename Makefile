GO_EASY_ON_ME = 1
SDKVERSION = 7.0
ARCHS = armv7 arm64

include theos/makefiles/common.mk
TWEAK_NAME = CamPad
CamPad_FILES = Tweak.xm
CamPad_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
