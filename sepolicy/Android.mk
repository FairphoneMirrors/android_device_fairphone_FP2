# Fairphone specific SELinux policy variable definitions
BOARD_SEPOLICY_DIRS += \
       device/fairphone_devices/sepolicy 

BOARD_SEPOLICY_UNION += \
       file_contexts \
       su.te
