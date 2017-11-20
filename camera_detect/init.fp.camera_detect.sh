#!/system/bin/sh

set -e
set -u
set -x

readonly PERSIST_PATH="persist"
readonly PROP_PATH="fp2.cam"

readonly ANY_FRAGMENT="any"
readonly SUBDEV_FRAGMENT="dev"
readonly SENSOR_FRAGMENT="sensor"
readonly CHANGED_FRAGMENT="changed"

readonly POSITIONS="main front"

readonly MAIN_SENSORS_PATTERN="(ov8865_q8v18a|ov12870)"
readonly FRONT_SENSORS_PATTERN="(ov2685|ov5670)"

readonly SYSFS_PATH="/sys/devices/fd8c0000.qcom,msm-cam/video4linux/*/name"


function _detect_front_sensor() {
  local sensor_name=`cat ${SYSFS_PATH} | grep -o -E "${FRONT_SENSORS_PATTERN}"`
  setprop \
      "${PROP_PATH}.front.${SENSOR_FRAGMENT}" \
      "${sensor_name}"
}


function _detect_main_sensor() {
  local sensor_name=`cat ${SYSFS_PATH} | grep -o -E "${MAIN_SENSORS_PATTERN}"`
  setprop \
      "${PROP_PATH}.main.${SENSOR_FRAGMENT}" \
      "${sensor_name}"
}


# Compare persist.* property with new property to detect if main or front
# Sensor has changed.
#
# Sets *.changed property to 1 for any sensor that has changed.
#
# Overwrites persist.* property with new sensor name.
function _detect_and_persist_sensor_change() {
    local changed_any_sensor=0

    for pos in ${POSITIONS}; do
        local changed_sensor=0

        local property="${PROP_PATH}.${pos}.${SENSOR_FRAGMENT}"

        local old_sensor="$(getprop "${PERSIST_PATH}.${property}")"
        local new_sensor="$(getprop "${property}")"

        # advocate change if:
        # a sensor is detected in the current position
        # AND a persist value is set (a camera was previously installed)
        # AND a different sensor is detected than stored in the persist value
        if [[ -n "${new_sensor}" ]] \
           && [[ -n "${old_sensor}" ]] \
           && [[ "${old_sensor}" != "${new_sensor}" ]] ; then
            setprop "${PROP_PATH}.${pos}.${CHANGED_FRAGMENT}" "1"
            changed_any_sensor=1
        fi

        # set new persist value with the new sensor name if it's non-empty
        if [[ -n "${new_sensor}" ]]; then
            setprop "${PERSIST_PATH}.${property}" "${new_sensor}"
        fi
    done

    echo "${changed_any_sensor}"
}


function _camera_detect_service() {
    _detect_main_sensor
    _detect_front_sensor
    local changed_any_sensor="$(_detect_and_persist_sensor_change)"
    setprop "${PROP_PATH}.${ANY_FRAGMENT}.${CHANGED_FRAGMENT}" \
        "${changed_any_sensor}"
}

_camera_detect_service
