#!/bin/bash

# Arcade Anomaly Test Script

GMOD_PATH="$HOME/.steam/debian-installation/steamapps/common/GarrysMod"
ADDONS_PATH="$GMOD_PATH/garrysmod/addons"
MAPS_PATH="$GMOD_PATH/garrysmod/maps"
ADDON_NAME="arcade_anomaly"

info() { echo "[INFO] $1"; }
ok() { echo "[OK] $1"; }
err() { echo "[ERR] $1"; }

# Show map menu and return selected map
pick_map() {
    # Build map list file
    local mapfile=$(mktemp)
    
    # Find maps in standard locations
    find "$MAPS_PATH" -name "*.bsp" -type f 2>/dev/null | while read f; do
        basename "$f" .bsp
    done >> "$mapfile"
    
    find "$GMOD_PATH/garrysmod/download/maps" -name "*.bsp" -type f 2>/dev/null | while read f; do
        basename "$f" .bsp
    done >> "$mapfile"
    
    # Find in addons
    for addon in "$ADDONS_PATH"/*; do
        if [ -d "$addon/maps" ]; then
            find "$addon/maps" -name "*.bsp" -type f 2>/dev/null | while read f; do
                basename "$f" .bsp
            done >> "$mapfile"
        fi
    done
    
    # Check if we found any maps
    if [ ! -s "$mapfile" ]; then
        err "No maps found!"
        rm -f "$mapfile"
        return 1
    fi
    
    # Sort and deduplicate, save to temp file with line numbers
    local sorted=$(mktemp)
    sort -u "$mapfile" > "$sorted"
    rm -f "$mapfile"
    
    local count=$(wc -l < "$sorted")
    ok "Found $count maps"
    echo ""
    
    # Display numbered list
    local i=1
    while read map; do
        echo "  $i) $map"
        i=$((i+1))
    done < "$sorted"
    
    echo "  0) Cancel"
    echo ""
    
    # Get user input
    while true; do
        read -p "Enter number (0-$count): " num
        
        # Cancel
        if [ "$num" = "0" ]; then
            rm -f "$sorted"
            return 1
        fi
        
        # Validate and get map
        if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "$count" ]; then
            local selected=$(sed -n "${num}p" "$sorted")
            rm -f "$sorted"
            echo "$selected"
            return 0
        fi
        
        err "Invalid: $num (enter 0-$count)"
    done
}

# Check GMod exists
check_gmod() {
    if [ ! -d "$GMOD_PATH" ]; then
        err "GMod not found: $GMOD_PATH"
        exit 1
    fi
}

# Install/reinstall addon
install_addon() {
    local target="$ADDONS_PATH/$ADDON_NAME"
    if [ -e "$target" ]; then
        rm -rf "$target"
    fi
    ln -s "$(pwd)" "$target"
    ok "Addon installed"
}

# Launch GMod with map
launch() {
    local map="$1"
    local dev="$2"
    local opts=""
    
    [ "$dev" = "true" ] && opts="$opts -console -dev 2"
    [ -n "$map" ] && opts="$opts +map $map"
    opts="$opts +aa_menu"
    
    info "Launching with map: $map"
    
    if command -v steam &>/dev/null; then
        steam -applaunch 4000 $opts &>/dev/null &
    elif [ -x "$GMOD_PATH/hl2.sh" ]; then
        (cd "$GMOD_PATH" && ./hl2.sh -game garrysmod $opts &>/dev/null &)    else
        err "Cannot launch GMod"
        return 1
    fi
    
    ok "GMod launching..."
}

# Quick launch workflow
quick_launch() {
    local dev="$1"
    local map=$(pick_map)
    
    if [ $? -eq 0 ] && [ -n "$map" ]; then
        check_gmod
        install_addon
        launch "$map" "$dev"
    else
        info "Cancelled"
    fi
}

# Main menu
show_menu() {
    while true; do
        echo ""
        echo "========== ARCADE ANOMALY =========="
        echo ""
        echo "1) Launch (pick map)"
        echo "2) Launch Dev Mode (pick map)"
        echo "3) Reinstall Addon"
        echo "4) Show Status"
        echo "5) Remove Addon"
        echo "0) Exit"
        echo ""
        read -p "Select: " c
        
        case "$c" in
            1) quick_launch "false" ;;
            2) quick_launch "true" ;;
            3) check_gmod && install_addon ;;
            4)
                check_gmod
                if [ -L "$ADDONS_PATH/$ADDON_NAME" ]; then
                    ok "Addon: Installed"
                else
                    err "Addon: Not installed"
                fi
                ;;
            5)
                check_gmod
                rm -rf "$ADDONS_PATH/$ADDON_NAME"
                ok "Addon removed"
                ;;
            0) echo "Bye!"; exit 0 ;;
            *) err "Invalid: $c" ;;
        esac
    done
}

# Handle command line
cmd="${1:-menu}"
case "$cmd" in
    menu|"") show_menu ;;
    install) check_gmod && install_addon ;;
    remove) check_gmod && rm -rf "$ADDONS_PATH/$ADDON_NAME" && ok "Removed" ;;
    launch) check_gmod && install_addon && [ -n "$2" ] && launch "$2" "false" ;;
    dev) check_gmod && install_addon && [ -n "$2" ] && launch "$2" "true" ;;
    go) quick_launch "false" ;;
    go-dev) quick_launch "true" ;;
    *) err "Unknown: $cmd"; exit 1 ;;
esac
