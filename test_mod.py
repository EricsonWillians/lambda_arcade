#!/usr/bin/env python3
"""
Arcade Anomaly - Professional Test Launcher v2.0
Python 3.6+ required

Flow improvements:
- Consistent back/cancel handling
- Better menu state management  
- Launch confirmation and status feedback
- Quick-launch with last used map
- Proper error recovery
"""

import os
import sys
import subprocess
import json
from pathlib import Path

# Configuration
GMOD_PATH = Path.home() / ".steam/debian-installation/steamapps/common/GarrysMod"
ADDONS_PATH = GMOD_PATH / "garrysmod/addons"
MAPS_PATH = GMOD_PATH / "garrysmod/maps"
DOWNLOAD_MAPS_PATH = GMOD_PATH / "garrysmod/download/maps"
ADDON_NAME = "arcade_anomaly"

# State file for remembering last map
STATE_FILE = Path.home() / ".arcade_anomaly_launcher.json"

# ANSI Colors
class Colors:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    MAGENTA = '\033[95m'
    BOLD = '\033[1m'
    DIM = '\033[2m'
    END = '\033[0m'

def info(msg): print(f"{Colors.BLUE}[INFO]{Colors.END} {msg}")
def ok(msg): print(f"{Colors.GREEN}[OK]{Colors.END} {msg}")
def err(msg): print(f"{Colors.RED}[ERR]{Colors.END} {msg}")
def warn(msg): print(f"{Colors.YELLOW}[WARN]{Colors.END} {msg}")
def dim(msg): print(f"{Colors.DIM}{msg}{Colors.END}")

def clear_screen():
    """Clear terminal screen"""
    os.system('clear' if os.name != 'nt' else 'cls')

def load_state():
    """Load launcher state (last map, etc)"""
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except:
            pass
    return {"last_map": None, "last_dev_mode": False}

def save_state(state):
    """Save launcher state"""
    try:
        STATE_FILE.write_text(json.dumps(state))
    except:
        pass

def check_gmod():
    """Verify GMod installation exists"""
    if not GMOD_PATH.exists():
        err(f"GMod not found at: {GMOD_PATH}")
        err("Please update GMOD_PATH in this script")
        input("\nPress Enter to exit...")
        sys.exit(1)
    if not ADDONS_PATH.exists():
        err(f"Addons folder not found")
        input("\nPress Enter to exit...")
        sys.exit(1)

def detect_maps():
    """Scan for all installed .bsp map files"""
    maps = set()
    
    search_paths = [MAPS_PATH, DOWNLOAD_MAPS_PATH]
    
    if ADDONS_PATH.exists():
        for addon_dir in ADDONS_PATH.iterdir():
            if addon_dir.is_dir():
                addon_maps = addon_dir / "maps"
                if addon_maps.exists():
                    search_paths.append(addon_maps)
    
    for path in search_paths:
        if path.exists():
            for bsp_file in path.glob("*.bsp"):
                maps.add(bsp_file.stem)
    
    return sorted(list(maps))

def draw_header(title, subtitle=None):
    """Draw consistent menu header"""
    print(f"\n{Colors.BOLD}{'='*60}{Colors.END}")
    print(f"{Colors.CYAN}{Colors.BOLD}  {title:^56}{Colors.END}")
    if subtitle:
        print(f"{Colors.DIM}  {subtitle:^56}{Colors.END}")
    print(f"{Colors.BOLD}{'='*60}{Colors.END}\n")

def draw_footer(options=None):
    """Draw consistent menu footer"""
    if options:
        print(f"\n  {Colors.DIM}Options: {options}{Colors.END}")
    print(f"\n  {Colors.YELLOW}[0] Back / Cancel{Colors.END}\n")

def select_map(maps, preselected=None):
    """
    Display interactive map selection menu with pagination.
    Returns: map_name or None (cancelled)
    """
    if not maps:
        err("No maps found!")
        info("Searched in:")
        print(f"  {MAPS_PATH}")
        print(f"  {DOWNLOAD_MAPS_PATH}")
        input("\nPress Enter to continue...")
        return None
    
    # Check if preselected map still exists
    if preselected and preselected in maps:
        use_last = input(f"\nUse last map '{preselected}'? [Y/n]: ").strip().lower()
        if use_last in ('', 'y', 'yes'):
            return preselected
    
    PAGE_SIZE = 15
    current_page = 0
    total_pages = (len(maps) + PAGE_SIZE - 1) // PAGE_SIZE
    
    while True:
        clear_screen()
        draw_header(f"SELECT MAP ({len(maps)} found)", f"Page {current_page + 1}/{total_pages}")
        
        start_idx = current_page * PAGE_SIZE
        end_idx = min(start_idx + PAGE_SIZE, len(maps))
        
        for i in range(start_idx, end_idx):
            map_name = maps[i]
            num = i - start_idx + 1
            # Highlight common maps
            prefix = "   "
            if any(x in map_name.lower() for x in ['construct', 'flatgrass', 'gm_']):
                prefix = f"{Colors.GREEN} * {Colors.END}"
            print(f"{prefix}{num:2}) {map_name}")
        
        nav_options = []
        if current_page > 0:
            nav_options.append("[P]rev")
        if current_page < total_pages - 1:
            nav_options.append("[N]ext")
        nav_options.append("[#] Select")
        nav_options.append("[0] Cancel")
        
        print(f"\n  {Colors.DIM}{' | '.join(nav_options)}{Colors.END}")
        
        try:
            choice = input("\n> ").strip().lower()
        except (KeyboardInterrupt, EOFError):
            print()
            return None
        
        # Cancel
        if choice in ('0', 'q', 'quit', 'cancel', ''):
            return None
        
        # Navigation
        if choice in ('p', 'prev') and current_page > 0:
            current_page -= 1
            continue
        if choice in ('n', 'next') and current_page < total_pages - 1:
            current_page += 1
            continue
        
        # Map selection
        try:
            idx = int(choice) - 1 + start_idx
            if 0 <= idx < len(maps):
                return maps[idx]
        except ValueError:
            # Try to find map by partial name
            matches = [m for m in maps if choice in m.lower()]
            if len(matches) == 1:
                return matches[0]
            elif len(matches) > 1:
                print(f"\n{Colors.YELLOW}Multiple matches:{Colors.END}")
                for i, m in enumerate(matches[:5], 1):
                    print(f"  {i}) {m}")
                input("\nPress Enter to continue...")
        
        err(f"Invalid: '{choice}'")
        input("Press Enter to continue...")

def install_addon():
    """Create symlink to install addon"""
    target = ADDONS_PATH / ADDON_NAME
    
    try:
        # Remove existing
        if target.exists() or target.is_symlink():
            if target.is_symlink():
                target.unlink()
                info("Removed old symlink")
            else:
                import shutil
                shutil.rmtree(target)
                warn("Removed old folder (was not symlink)")
        
        # Create symlink
        source = Path.cwd()
        target.symlink_to(source)
        ok(f"Addon linked: {target}")
        return True
        
    except Exception as e:
        err(f"Failed to install addon: {e}")
        return False

def remove_addon():
    """Remove addon symlink/folder"""
    target = ADDONS_PATH / ADDON_NAME
    
    try:
        if target.exists() or target.is_symlink():
            if target.is_symlink():
                target.unlink()
            else:
                import shutil
                shutil.rmtree(target)
            ok("Addon removed")
            return True
        else:
            warn("Addon not found")
            return False
    except Exception as e:
        err(f"Failed to remove addon: {e}")
        return False

def launch_gmod(map_name, dev_mode=False):
    """Launch Garry's Mod with specified options"""
    opts = ["-condebug"]
    
    if dev_mode:
        opts.extend(["-console", "-dev", "2"])
    
    if map_name:
        opts.extend(["+map", map_name])
    
    opts.append("+aa_menu")
    
    info(f"Launching with map: {map_name}")
    info("Console log: garrysmod/console.log")
    
    launched = False
    
    # Try Steam first
    try:
        result = subprocess.run(["which", "steam"], capture_output=True)
        if result.returncode == 0:
            cmd = ["steam", "-applaunch", "4000"] + opts
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            ok("Launched via Steam")
            launched = True
    except Exception:
        pass
    
    # Direct launch fallback
    if not launched:
        hl2_sh = GMOD_PATH / "hl2.sh"
        if hl2_sh.exists():
            cmd = ["./hl2.sh", "-game", "garrysmod"] + opts
            subprocess.Popen(cmd, cwd=GMOD_PATH, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            ok("Launched directly")
            launched = True
        else:
            err("Cannot find GMod launch method")
            return False
    
    if launched:
        save_state({"last_map": map_name, "last_dev_mode": dev_mode})
    
    return launched

def show_status():
    """Show addon installation status"""
    check_gmod()
    
    clear_screen()
    draw_header("ADDON STATUS")
    
    target = ADDONS_PATH / ADDON_NAME
    state = load_state()
    
    print(f"  Working dir: {Path.cwd()}")
    print(f"  GMod path:   {GMOD_PATH}")
    print(f"  Addons path: {ADDONS_PATH}")
    print()
    
    if target.is_symlink():
        ok("Addon: Installed (symlink)")
        print(f"  → {target.resolve()}")
    elif target.exists():
        warn("Addon: Installed (folder, not symlink)")
    else:
        err("Addon: Not installed")
    
    maps = detect_maps()
    print(f"\n  Maps available: {len(maps)}")
    
    lua_files = list(Path("lua").rglob("*.lua")) if Path("lua").exists() else []
    print(f"  Lua files: {len(lua_files)}")
    
    if state.get("last_map"):
        print(f"\n  {Colors.CYAN}Last used map:{Colors.END} {state['last_map']}")
        print(f"  {Colors.DIM}Last mode:{Colors.END} {'Dev' if state.get('last_dev_mode') else 'Normal'}")

def quick_launch():
    """Quick launch with last used settings"""
    state = load_state()
    last_map = state.get("last_map")
    
    maps = detect_maps()
    
    if not last_map or last_map not in maps:
        warn("No previous map found or map no longer exists")
        return select_map_and_launch(dev_mode=False)
    
    clear_screen()
    draw_header("QUICK LAUNCH")
    
    print(f"  Map: {Colors.CYAN}{last_map}{Colors.END}")
    print(f"  Mode: {Colors.DIM}Normal{Colors.END}\n")
    
    confirm = input("Launch? [Y/n/s]elect other: ").strip().lower()
    
    if confirm in ('', 'y', 'yes'):
        if install_addon():
            launch_gmod(last_map, dev_mode=False)
            return True
    elif confirm == 's':
        return select_map_and_launch(dev_mode=False)
    
    return False

def select_map_and_launch(dev_mode=False):
    """Unified map selection and launch flow"""
    maps = detect_maps()
    state = load_state()
    
    map_name = select_map(maps, preselected=state.get("last_map") if not dev_mode else None)
    
    if not map_name:
        return False
    
    # Show launch confirmation
    clear_screen()
    mode_str = "DEV MODE" if dev_mode else "NORMAL"
    draw_header(f"LAUNCH - {mode_str}")
    print(f"\n  Map: {Colors.CYAN}{map_name}{Colors.END}")
    print(f"  Mode: {Colors.GREEN if dev_mode else Colors.DIM}{mode_str}{Colors.END}\n")
    
    # Install and launch
    if not install_addon():
        input("\nPress Enter to continue...")
        return False
    
    launch_gmod(map_name, dev_mode=dev_mode)
    return True

def show_menu():
    """Main interactive menu with improved flow"""
    state = load_state()
    
    while True:
        clear_screen()
        draw_header("ARCADE ANOMALY - TEST MENU")
        
        # Show current status
        target = ADDONS_PATH / ADDON_NAME
        status = f"{Colors.GREEN}✓{Colors.END}" if target.exists() else f"{Colors.RED}✗{Colors.END}"
        
        last_map_str = ""
        if state.get("last_map"):
            last_map_str = f" {Colors.DIM}(last: {state['last_map']}){Colors.END}"
        
        print(f"  Addon: {status} {ADDON_NAME}")
        print()
        print(f"  {Colors.BOLD}1){Colors.END} Quick Launch{last_map_str}")
        print(f"  {Colors.BOLD}2){Colors.END} Launch with Map Selection")
        print(f"  {Colors.BOLD}3){Colors.END} Launch Dev Mode")
        print()
        print(f"  {Colors.BOLD}4){Colors.END} Reinstall Addon")
        print(f"  {Colors.BOLD}5){Colors.END} Remove Addon")
        print(f"  {Colors.BOLD}6){Colors.END} Show Status")
        print(f"  {Colors.BOLD}7){Colors.END} Refresh Map List")
        print()
        print(f"  {Colors.RED}{Colors.BOLD}0){Colors.END} Exit")
        print()
        
        try:
            choice = input("Select: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\n\nGoodbye!")
            sys.exit(0)
        
        if choice == "1":
            check_gmod()
            quick_launch()
            input("\nPress Enter to continue...")
        
        elif choice == "2":
            check_gmod()
            select_map_and_launch(dev_mode=False)
            input("\nPress Enter to continue...")
        
        elif choice == "3":
            check_gmod()
            select_map_and_launch(dev_mode=True)
            input("\nPress Enter to continue...")
        
        elif choice == "4":
            check_gmod()
            install_addon()
            input("\nPress Enter to continue...")
        
        elif choice == "5":
            check_gmod()
            remove_addon()
            input("\nPress Enter to continue...")
        
        elif choice == "6":
            show_status()
            input("\nPress Enter to continue...")
        
        elif choice == "7":
            info("Refreshing map list...")
            maps = detect_maps()
            ok(f"Found {len(maps)} maps")
            input("\nPress Enter to continue...")
        
        elif choice == "0":
            print("\nGoodbye!\n")
            sys.exit(0)
        
        else:
            err(f"Invalid option: '{choice}'")
            input("\nPress Enter to continue...")

def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Arcade Anomaly Test Launcher",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  ./test_mod.py              Interactive menu
  ./test_mod.py quick        Quick launch (last map)
  ./test_mod.py launch MAP   Launch specific map
  ./test_mod.py dev MAP      Launch map in dev mode
  ./test_mod.py install      Install addon only
  ./test_mod.py remove       Remove addon
  ./test_mod.py status       Show status
        """
    )
    
    parser.add_argument("command", nargs="?", default="menu",
                       help="Command to run")
    parser.add_argument("map", nargs="?", help="Map name for launch commands")
    parser.add_argument("-d", "--dev", action="store_true", 
                       help="Enable dev mode for launch")
    
    args = parser.parse_args()
    
    # Ensure GMod exists for commands that need it
    if args.command in ('launch', 'dev', 'install', 'remove', 'quick', 'menu'):
        check_gmod()
    
    if args.command == "menu" or args.command == "":
        show_menu()
    
    elif args.command == "quick":
        quick_launch()
    
    elif args.command == "install":
        install_addon()
    
    elif args.command == "remove":
        remove_addon()
    
    elif args.command == "status":
        show_status()
    
    elif args.command == "launch":
        if args.map:
            install_addon()
            launch_gmod(args.map, dev_mode=args.dev)
        else:
            select_map_and_launch(dev_mode=args.dev)
    
    elif args.command == "dev":
        if args.map:
            install_addon()
            launch_gmod(args.map, dev_mode=True)
        else:
            select_map_and_launch(dev_mode=True)
    
    else:
        err(f"Unknown command: {args.command}")
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
