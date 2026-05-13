#!/usr/bin/env sh

# Core command to set Colemak-DH keyboard layout in X11
use_colemak_layout() {
    setxkbmap -model pc105 \
              -layout us \
              -variant colemak_dh \
              caps:escape_shifted_capslock \
              2>/dev/null || true
    xset r rate 250 30
}

# Connect to X server and set keyboard layout
set_x11_colemak() {
    real_user=$(logname 2>/dev/null || echo "${SUDO_USER:-}")

    if [ -z "$real_user" ] || [ "$real_user" = "root" ]; then
        echo "Warning: Could not determine original user" >&2
        return 1
    fi

    DISPLAY=${DISPLAY:-:0}
    export DISPLAY

    user_home=$(getent passwd "$real_user" | cut -d: -f6)
    user_xauth="$user_home/.Xauthority"

    if [ -f "$user_xauth" ]; then
        export XAUTHORITY="$user_xauth"
    fi

    if command -v xdpyinfo >/dev/null 2>&1 && xdpyinfo >/dev/null 2>&1; then
        echo "Setting Colemak-DH X11 layout for root user (DISPLAY=$DISPLAY)" >&2
        use_colemak_layout
        return 0
    else
        echo "Warning: Cannot connect to X server (DISPLAY=$DISPLAY)" >&2
        return 1
    fi
}

# Set keyboard layout to colemak
case "$(tty 2>/dev/null)" in
    /dev/ttyv* | /dev/console | /dev/tty*)
        # We are on a virtual console -> use kbdcontrol to switch layout
        if command -v kbdmap >/dev/null 2>&1; then
            echo "Setting Colemak-DH console keymap for root user" >&2
            kbdcontrol -r fast -l colemak-dh.iso.acc.kbd || true
        fi
        ;;
    *)
        # We are not on a virtual console, this could be X11, SSH, tmux, etc.
        if command -v setxkbmap >/dev/null 2>&1; then
            set_x11_colemak
        fi
        ;;
esac
