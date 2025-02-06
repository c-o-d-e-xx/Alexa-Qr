#!/system/bin/sh

##########################################################################################
# Installer Script for Emojify
##########################################################################################

# Script Details
AUTOMOUNT=true
SKIPMOUNT=false
PROPFILE=false
POSTFSDATA=false
LATESTARTSERVICE=true

ui_print "*******************************"
ui_print "*    Emojify V 1.2.3 🚀       *"
ui_print "*******************************"

# Definitions
FONT_DIR="$MODPATH/system/fonts"
IOS_EMOJI="IosEmoji.ttf"
WINDOWS_EMOJI="Windows_Emoji.ttf"
TARGET_FONT="NotoColorEmoji.ttf"

# Emoji selection options (using positional parameters for sh compatibility)
OPTION_0="default"
OPTION_1="iOS"
OPTION_2="Windows"
SELECTED_OPTION="$OPTION_0"

# Function to replace the system emoji font with the selected font
replace_system_font() {
    local selected_font
    case "$1" in
        "iOS")
            selected_font="$IOS_EMOJI"
            ;;
        "Windows")
            selected_font="$WINDOWS_EMOJI"
            ;;
        "default")
            ui_print "- No changes to the system emoji (default behavior)"
            return
            ;;
        *)
            ui_print "- Invalid emoji type, defaulting to system emoji"
            return
            ;;
    esac

    if [ -f "$FONT_DIR/$selected_font" ]; then
        ui_print "- Replacing system emoji font with $1 emojis"
        cp -f "$FONT_DIR/$selected_font" "$FONT_DIR/$TARGET_FONT" || {
            ui_print "- Failed to replace system font"
            exit 1
        }
    else
        ui_print "- Font file for $1 not found, skipping replacement"
    fi
}

# Function to handle emoji selection using volume buttons
select_emoji() {
    ui_print "Select emoji type using volume buttons:"
    ui_print "Volume Down: Change selection"
    ui_print "Volume Up: Confirm selection"

    local current_index=0
    local total_options=3

    while true; do
        # Display the current selection
        case "$current_index" in
            0) SELECTED_OPTION="$OPTION_0" ;;
            1) SELECTED_OPTION="$OPTION_1" ;;
            2) SELECTED_OPTION="$OPTION_2" ;;
        esac
        ui_print "Current selection: $SELECTED_OPTION"
        ui_print "Waiting for input..."

        # Read volume key input
        input=$(getevent -lc 1 2>/dev/null | grep -E "KEY_VOLUMEUP|KEY_VOLUMEDOWN")

        if echo "$input" | grep -q "KEY_VOLUMEDOWN"; then
            current_index=$(( (current_index + 1) % total_options ))
        elif echo "$input" | grep -q "KEY_VOLUMEUP"; then
            break
        fi
    done
}

# Extract module files
ui_print "- Extracting module files"
unzip -o "$ZIPFILE" 'system/*' -d "$MODPATH" >&2 || {
    ui_print "- Failed to extract module files"
    exit 1
}

# Emoji selection process
select_emoji
ui_print "- Selected emoji: $SELECTED_OPTION"

# Replace the system font only if a specific emoji type is selected
replace_system_font "$SELECTED_OPTION"

# Remove /data/fonts directory for Android 12+ instead of replacing the files
if [ -d "/data/fonts" ]; then
    rm -rf "/data/fonts"
    ui_print "- Removed existing /data/fonts directory"
fi

# Set permissions
ui_print "- Setting Permissions"
set_perm_recursive "$MODPATH" 0 0 0755 0644

ui_print "- Done"
ui_print "- Custom emojis installed successfully!"
ui_print "- Reboot your device to apply changes."
ui_print "- Enjoy your new emojis! :)"

# OverlayFS Support
OVERLAY_IMAGE_EXTRA=0
OVERLAY_IMAGE_SHRINK=true

# Only use OverlayFS if Magisk_OverlayFS is installed
if [ -f "/data/adb/modules/magisk_overlayfs/util_functions.sh" ] && \
    /data/adb/modules/magisk_overlayfs/overlayfs_system --test; then
  ui_print "- Add support for overlayfs"
  . /data/adb/modules/magisk_overlayfs/util_functions.sh
  support_overlayfs && rm -rf "$MODPATH"/system
fi
