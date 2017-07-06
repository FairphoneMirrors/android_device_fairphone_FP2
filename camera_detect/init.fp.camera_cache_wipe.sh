#!/system/bin/sh

set -e
set -u

readonly FILES_TO_WIPE="\
    com.google.android.GoogleCamera/shared_prefs/com.google.android.GoogleCamera_preferences.xml \
    com.android.camera2/shared_prefs/com.android.camera2_preferences.xml
"
readonly PREFERENCE_TO_WIPE="CachedSupportedPictureSizes_Build_Camera"

# Precondition: file_to_wipe exists
function _remove_preference() {
    local file_to_wipe="$(readlink -f "$1")"

    local owner=$(stat -c '%U' "${file_to_wipe}")
    local group=$(stat -c '%G' "${file_to_wipe}")
    local access_bits="$(stat -c '%a' "${file_to_wipe}")"
    local context="$(ls -Z "${file_to_wipe}" | grep -o "u:object_r:[^ ]*")"

    sed -i "/${PREFERENCE_TO_WIPE}/d" "${file_to_wipe}"

    chown -f ${owner} "${file_to_wipe}"
    chgrp -f ${group} "${file_to_wipe}"
    chmod "${access_bits}" "${file_to_wipe}"
    chcon "${context}" "${file_to_wipe}"
}

for f in ${FILES_TO_WIPE}; do
    for user in /data/user/*; do
        if [[ -f "${user}/${f}" ]]; then
            _remove_preference "${user}/${f}"
        fi
    done
done

