#!/bin/sh
set -eu
printf 'fake_retrorun=1\n'
printf 'device_name=%s\n' "${DEVICE_NAME-}"
printf 'egl=%s\n' "${SDL_VIDEO_EGL_DRIVER-}"
printf 'mapping=%s\n' "${SDL_GAMECONTROLLERCONFIG-}"
printf 'argc=%s\n' "$#"
printf 'argv=%s\n' "$*"
exit 0
