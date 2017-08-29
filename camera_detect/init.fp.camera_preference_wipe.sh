#!/system/bin/sh

set -e
set -u

readonly FILES_TO_WIPE="\
    com.google.android.GoogleCamera/shared_prefs/com.google.android.GoogleCamera_preferences.xml \
    com.android.camera2/shared_prefs/com.android.camera2_preferences.xml
"
readonly PREFERENCE_TO_WIPE_RES_CACHE="CachedSupportedPictureSizes_Build_Camera"
readonly PREFERENCE_TO_WIPE_RES_FRONT="pref_camera_picturesize_front_key"
readonly PREFERENCE_TO_WIPE_RES_MAIN="pref_camera_picturesize_main_key"

readonly ANY_CAM_CHANGED_PROPERTY="fp2.cam.any.changed"
readonly FRONT_CAM_CHANGED_PROPERTY="fp2.cam.front.changed"
readonly MAIN_CAM_CHANGED_PROPERTY="fp2.cam.main.changed"

readonly ANY_CAM_CHANGED="$(getprop "${ANY_CAM_CHANGED_PROPERTY}")"
readonly FRONT_CAM_CHANGED="$(getprop "${FRONT_CAM_CHANGED_PROPERTY}")"
readonly MAIN_CAM_CHANGED="$(getprop "${MAIN_CAM_CHANGED_PROPERTY}")"


# Precondition: file_to_wipe exists
function _remove_preferences() {
    local file_to_wipe="$(readlink -f "$1")"

    local owner=$(stat -c '%U' "${file_to_wipe}")
    local group=$(stat -c '%G' "${file_to_wipe}")
    local access_bits="$(stat -c '%a' "${file_to_wipe}")"
    local context="$(ls -Z "${file_to_wipe}" | grep -o "u:object_r:[^ ]*")"

    if [ "$ANY_CAM_CHANGED"=="1" ]
        then
        sed -i "/${PREFERENCE_TO_WIPE_RES_CACHE}/d" "${file_to_wipe}"
    fi

    if [ "$FRONT_CAM_CHANGED"=="1" ]
        then
        sed -i "/${PREFERENCE_TO_WIPE_RES_FRONT}/d" "${file_to_wipe}"
    fi

    if [ "$MAIN_CAM_CHANGED"=="1" ]
        then
        sed -i "/${PREFERENCE_TO_WIPE_RES_MAIN}/d" "${file_to_wipe}"
    fi

    chown -f ${owner} "${file_to_wipe}"
    chgrp -f ${group} "${file_to_wipe}"
    chmod "${access_bits}" "${file_to_wipe}"
    chcon "${context}" "${file_to_wipe}"
}


for f in ${FILES_TO_WIPE}; do
    for user in /data/user/*; do
        if [[ -f "${user}/${f}" ]]; then
            _remove_preferences "${user}/${f}"
        fi
    done
done
