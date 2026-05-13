#!/usr/bin/env sh

# Core command to set Colemak-DH keyboard layout in X11
switch_x11_layout() {
    if [ "$layout" = "colemak" ]; then
        setxkbmap -model pc105 \
                  -layout us \
                  -variant colemak_dh \
                  caps:escape_shifted_capslock \
                  2>/dev/null || true
    else
        setxkbmap -model pc105 \
                  -layout us
                  2>/dev/null || true
    fi
    xset r rate 250 30
}


switch_vt_layout() {
    echo "Setting virtual terminal keyboard layout" >&2
    if [ "$layout" = "colemak" ]; then
        kbdcontrol -r fast -l colemak-dh.iso.acc.kbd || true
    else
        kbdcontrol -r fast -l us.acc.kbd || true
    fi
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
        echo "Setting X11 keyboard layout (DISPLAY=$DISPLAY)" >&2
        use_colemak_layout
        return 0
    else
        echo "Warning: Cannot connect to X server (DISPLAY=$DISPLAY)" >&2
        return 1
    fi
}

# Set keyboard layout

layout=$1
case "$(tty 2>/dev/null)" in
    /dev/ttyv* | /dev/console | /dev/tty*)
        # We are on a virtual console
        if command -v kbdmap >/dev/null 2>&1; then
            switch_vt_layout
        fi
        ;;
    *)
        # We are not on a virtual console, this could be X11, SSH, tmux, etc.
        if command -v setxkbmap >/dev/null 2>&1; then
            switch_x11_layout
        fi
        ;;
esac
