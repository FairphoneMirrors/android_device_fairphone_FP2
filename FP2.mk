# Inherit from variables defined elsewhere first (they could tune this file)
$(call inherit-product-if-exists, vendor/fairphone-extra/fairphone-extra.mk)

TARGET_USES_QCOM_BSP := true
TARGET_USES_QCA_NFC := other

ifeq ($(TARGET_USES_QCOM_BSP), true)
# Add QC Video Enhancements flag
TARGET_ENABLE_QC_AV_ENHANCEMENTS := true
endif #TARGET_USES_QCOM_BSP

#TARGET_DISABLE_DASH := true
#TARGET_DISABLE_OMX_SECURE_TEST_APP := true

# media_profiles and media_codecs xmls for 8974
ifeq ($(TARGET_ENABLE_QC_AV_ENHANCEMENTS), true)
PRODUCT_COPY_FILES += device/fairphone_devices/FP2/media/media_profiles_8974.xml:system/etc/media_profiles.xml \
                      device/fairphone_devices/FP2/media/media_codecs_8974.xml:system/etc/media_codecs.xml \
                      device/fairphone_devices/FP2/media/media_codecs_performance_8974.xml:system/etc/media_codecs_performance.xml
endif  #TARGET_ENABLE_QC_AV_ENHANCEMENTS

PRODUCT_COPY_FILES += \
    device/fairphone_devices/FP2/old-apns-conf.xml:system/etc/old-apns-conf.xml

PRODUCT_COPY_FILES += \
    device/fairphone_devices/FP2/apns-conf.xml:system/etc/apns-conf.xml

PRODUCT_PROPERTY_OVERRIDES += ro.frp.pst=/dev/block/bootdevice/by-name/pad

# Do not enable data roaming by default
PRODUCT_PROPERTY_OVERRIDES := $(filter-out ro.com.android.dataroaming=%,\
    $(PRODUCT_PROPERTY_OVERRIDES)) \
    ro.com.android.dataroaming=false

# Set default alarm sound
PRODUCT_PROPERTY_OVERRIDES += \
    ro.config.alarm_alert=Cesium.ogg

# Allow mediaserver to allocate up to 75% of total RAM
PRODUCT_PROPERTY_OVERRIDES += \
    ro.media.maxmem=1451891712

# setup dalvik vm configs.
$(call inherit-product, frameworks/native/build/phone-xhdpi-2048-dalvik-heap.mk)

# Vendor-specific definitions, including branding assets
$(call inherit-product, vendor/fairphone/FP2/device-vendor.mk)

# Common definitions to set undefined properties
$(call inherit-product, device/qcom/common/common.mk)

PRODUCT_NAME := FP2
PRODUCT_DEVICE := FP2
PRODUCT_BRAND := Fairphone
PRODUCT_MANUFACTURER := Fairphone
PRODUCT_PROPERTY_OVERRIDES += \
    ro.com.google.clientidbase=android-fairphone

# Audio configuration file
PRODUCT_COPY_FILES += \
    device/fairphone_devices/FP2/audio_policy.conf:system/etc/audio_policy.conf \
    device/fairphone_devices/FP2/audio_effects.conf:system/vendor/etc/audio_effects.conf \
    device/fairphone_devices/FP2/mixer_paths.xml:system/etc/mixer_paths.xml \
    device/fairphone_devices/FP2/mixer_paths_auxpcm.xml:system/etc/mixer_paths_auxpcm.xml

# Display logo image file

PRODUCT_PACKAGES += \
    libqcomvisualizer \
    libqcomvoiceprocessing \
    libqcompostprocbundle

# Feature definition files for 8974
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.sensor.accelerometer.xml:system/etc/permissions/android.hardware.sensor.accelerometer.xml \
    frameworks/native/data/etc/android.hardware.sensor.compass.xml:system/etc/permissions/android.hardware.sensor.compass.xml \
    frameworks/native/data/etc/android.hardware.sensor.gyroscope.xml:system/etc/permissions/android.hardware.sensor.gyroscope.xml \
    frameworks/native/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/native/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepcounter.xml:system/etc/permissions/android.hardware.sensor.stepcounter.xml \
    frameworks/native/data/etc/android.hardware.sensor.stepdetector.xml:system/etc/permissions/android.hardware.sensor.stepdetector.xml

#battery_monitor
PRODUCT_PACKAGES += \
    battery_monitor \
    battery_shutdown

#fstab.qcom
PRODUCT_PACKAGES += fstab.qcom

#wlan driver
PRODUCT_COPY_FILES += \
    device/fairphone_devices/FP2/WCNSS_qcom_cfg.ini:system/etc/wifi/WCNSS_qcom_cfg.ini \
    device/fairphone_devices/FP2/WCNSS_qcom_wlan_nv.bin:persist/WCNSS_qcom_wlan_nv.bin

PRODUCT_PACKAGES += \
    wpa_supplicant_overlay.conf \
    p2p_supplicant_overlay.conf

PRODUCT_PACKAGES += wcnss_service

# MIDI feature
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.software.midi.xml:system/etc/permissions/android.software.midi.xml
#ANT stack
PRODUCT_PACKAGES += \
        AntHalService \
        libantradio \
        ANTRadioService \
        antradio_app
TARGET_RELEASETOOLS_EXTENSIONS := device/fairphone_devices/FP2
ADD_RADIO_FILES := true

# Enable strict operation
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.strict_op_enable=false

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.whitelist=/system/etc/whitelist_appops.xml

PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    camera2.portability.force_api=1

PRODUCT_COPY_FILES += \
    device/fairphone_devices/FP2/whitelist_appops.xml:system/etc/whitelist_appops.xml


# NFC packages
ifeq ($(TARGET_USES_QCA_NFC),true)
NFC_D := true

ifeq ($(NFC_D), true)
    PRODUCT_PACKAGES += \
        libnfcD-nci \
        libnfcD_nci_jni \
        nfc_nci.msm8974 \
        NfcDNci \
        Tag \
        com.android.nfc_extras \
        com.android.nfc.helper
else
PRODUCT_PACKAGES += \
    libnfc-nci \
    libnfc_nci_jni \
    nfc_nci.msm8974 \
    NfcNci \
    Tag \
    com.android.nfc_extras
endif

# file that declares the MIFARE NFC constant
# Commands to migrate prefs from com.android.nfc3 to com.android.nfc
# NFC access control + feature files + configuration
PRODUCT_COPY_FILES += \
        frameworks/native/data/etc/com.nxp.mifare.xml:system/etc/permissions/com.nxp.mifare.xml \
        frameworks/native/data/etc/com.android.nfc_extras.xml:system/etc/permissions/com.android.nfc_extras.xml \
        frameworks/native/data/etc/android.hardware.nfc.xml:system/etc/permissions/android.hardware.nfc.xml
# Enable NFC Forum testing by temporarily changing the PRODUCT_BOOT_JARS
# line has to be in sync with build/target/product/core_base.mk
endif

PRODUCT_BOOT_JARS += qcmediaplayer \
                     org.codeaurora.Performance \
                     vcard \
                     tcmiface
ifneq ($(strip $(QCPATH)),)
PRODUCT_BOOT_JARS += WfdCommon
PRODUCT_BOOT_JARS += qcom.fmradio
PRODUCT_BOOT_JARS += security-bridge
PRODUCT_BOOT_JARS += qsb-port
PRODUCT_BOOT_JARS += oem-services
PRODUCT_BOOT_JARS += com.qti.dpmframework
PRODUCT_BOOT_JARS += dpmapi
PRODUCT_BOOT_JARS += com.qti.location.sdk
endif

PRODUCT_PACKAGES += \
                    FairphoneUpdater \
                    ProgrammableButton \
                    FairphoneCheckup \
		    FairphoneLauncher3

PRODUCT_PACKAGES += iFixit

PRODUCT_COPY_FILES += device/fairphone_devices/FP2/twrp.fstab:recovery/root/etc/twrp.fstab

PRODUCT_MODEL := FP2

# include an expanded selection of fonts for the SDK.
EXTENDED_FONT_FOOTPRINT := true

# remove /dev/diag in user version for CTS
ifeq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_COPY_FILES += device/qcom/common/rootdir/etc/init.qcom.diag.rc.user:root/init.qcom.diag.rc
endif

# Enable the diagnostics interface by default in userdebug and eng builds
ifneq (,$(filter userdebug eng,$(TARGET_BUILD_VARIANT)))
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=diag
endif

ifeq ($(strip $(FP2_SKIP_BOOT_JARS_CHECK)),)
SKIP_BOOT_JARS_CHECK := true
endif

PRODUCT_PACKAGE_OVERLAYS += device/fairphone_devices/FP2/overlay

# SuperUser
FP2_USE_APPOPS_SU := true
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.root_access=0

# we don't have the calibration data so don't generate persist.img
FP2_SKIP_PERSIST_IMG := true

# display density
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=480

$(call inherit-product, build/target/product/product_launched_with_l_mr1.mk)

PRODUCT_PACKAGES += \
    libhealthd.FP2

PRODUCT_PACKAGES += xdivert

# We need to ship Mms for backward compatibility
PRODUCT_PACKAGES += Mms

# Ship the ModuleDetect app to inform users of a sucessful camera swap
PRODUCT_PACKAGES += ModuleDetect
PRODUCT_PACKAGES += CameraSwapInfo

# Ship the sound recorder app for backward compatibility with previous releases
PRODUCT_PACKAGES += SoundRecorder

# ProximitySensor app
PRODUCT_PACKAGES += ProximitySensorTools

# Detection of what cameras are installed
PRODUCT_PACKAGES += \
					  init.fp.camera_detect.rc \
					  init.fp.camera_detect.sh \
					  init.fp.camera_preference_wipe.sh

BOARD_SEPOLICY_DIRS += \
					   device/fairphone_devices/FP2/camera_detect/sepolicy

PRODUCT_PACKAGES += senread
