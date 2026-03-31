#!/usr/bin/env python3
"""
Arcade Anomaly - Professional Test Launcher
Python 3.6+ required
"""

import os
import sys
import subprocess
import glob
from pathlib import Path

# Configuration
GMOD_PATH = Path.home() / ".steam/debian-installation/steamapps/common/GarrysMod"
ADDONS_PATH = GMOD_PATH / "garrysmod/addons"
MAPS_PATH = GMOD_PATH / "garrysmod/maps"
DOWNLOAD_MAPS_PATH = GMOD_PATH / "garrysmod/download/maps"
ADDON_NAME = "arcade_anomaly"

# ANSI Colors
class Colors:
    BLUE = '\033[94m'
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    END = '\033[0m'

def info(msg): print(f"{Colors.BLUE}[INFO]{Colors.END} {msg}")
def ok(msg): print(f"{Colors.GREEN}[OK]{Colors.END} {msg}")
def err(msg): print(f"{Colors.RED}[ERR]{Colors.END} {msg}")
def warn(msg): print(f"{Colors.YELLOW}[WARN]{Colors.END} {msg}")

def clear_screen():
    """Clear terminal screen"""
    os.system('clear' if os.name != 'nt' else 'cls')

def check_gmod():
    """Verify GMod installation exists"""
    if not GMOD_PATH.exists():
        err(f"GMod not found at: {GMOD_PATH}")
        sys.exit(1)
    if not ADDONS_PATH.exists():
        err(f"Addons folder not found")
        sys.exit(1)

def detect_maps():
    """Scan for all installed .bsp map files"""
    maps = set()
    
    # Search paths
    search_paths = [
        MAPS_PATH,
        DOWNLOAD_MAPS_PATH,
    ]
    
    # Add addon map folders
    if ADDONS_PATH.exists():
        for addon_dir in ADDONS_PATH.iterdir():
            if addon_dir.is_dir():
                addon_maps = addon_dir / "maps"
                if addon_maps.exists():
                    search_paths.append(addon_maps)
    
    # Find all .bsp files
    for path in search_paths:
        if path.exists():
            for bsp_file in path.glob("*.bsp"):
                maps.add(bsp_file.stem)
    
    return sorted(list(maps))

def select_map(maps):
    """Display interactive map selection menu"""
    if not maps:
        err("No maps found!")
        info("Searched in:")
        print(f"  {MAPS_PATH}")
        print(f"  {DOWNLOAD_MAPS_PATH}")
        return None
    
    while True:
        clear_screen()
        print(f"\n{Colors.BOLD}{'='*50}{Colors.END}")
        print(f"{Colors.CYAN}{Colors.BOLD}  SELECT MAP ({len(maps)} found){Colors.END}")
        print(f"{Colors.BOLD}{'='*50}{Colors.END}\n")
        
        # Display maps (10 per page for readability)
        for i, map_name in enumerate(maps, 1):
            print(f"  {i:2}) {map_name}")
        
        print(f"\n  {Colors.YELLOW}0){Colors.END} Cancel")
        print(f"\n  Enter number 0-{len(maps)}")
        
        try:
            choice = input("\n> ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\n")
            return None
        
        # Cancel
        if choice == "0" or choice == "":
            return None
        
        # Validate
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(maps):
                return maps[idx]
        except ValueError:
            pass
        
        err(f"Invalid: '{choice}'")
        input("Press Enter to continue...")

def install_addon():
    """Create symlink to install addon"""
    target = ADDONS_PATH / ADDON_NAME
    
    # Remove existing
    if target.exists() or target.is_symlink():
        if target.is_symlink():
            target.unlink()
        else:
            import shutil
            shutil.rmtree(target)
    
    # Create symlink
    source = Path.cwd()
    target.symlink_to(source)
    ok(f"Addon linked: {target}")

def launch_gmod(map_name, dev_mode=False):
    """Launch Garry's Mod with specified options"""
    opts = []
    
    # Always enable console logging for debugging
    opts.append("-condebug")
    
    if dev_mode:
        opts.extend(["-console", "-dev", "2"])
    
    if map_name:
        opts.extend(["+map", map_name])
    
    opts.append("+aa_menu")
    
    info(f"Launching GMod with map: {map_name}")
    info("Console log will be saved to: garrysmod/console.log")
    
    # Try Steam first, then direct launch
    try:
        # Check if steam command exists
        result = subprocess.run(["which", "steam"], capture_output=True)
        if result.returncode == 0:
            cmd = ["steam", "-applaunch", "4000"] + opts
            subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            ok("Launched via Steam")
            return
    except Exception:
        pass
    
    # Direct launch fallback
    hl2_sh = GMOD_PATH / "hl2.sh"
    if hl2_sh.exists():
        cmd = ["./hl2.sh", "-game", "garrysmod"] + opts
        subprocess.Popen(cmd, cwd=GMOD_PATH, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        ok("Launched directly")
    else:
        err("Cannot find GMod launch method")

def show_status():
    """Show addon installation status"""
    check_gmod()
    
    print(f"\n{'='*50}")
    print("  ADDON STATUS")
    print(f"{'='*50}\n")
    
    target = ADDONS_PATH / ADDON_NAME
    
    print(f"Working dir: {Path.cwd()}")
    print(f"GMod path:   {GMOD_PATH}")
    print(f"Addons path: {ADDONS_PATH}")
    print()
    
    if target.is_symlink():
        ok("Addon: Installed (symlink)")
        print(f"  Points to: {target.resolve()}")
    elif target.exists():
        warn("Addon: Installed (folder, not symlink)")
    else:
        err("Addon: Not installed")
    
    maps = detect_maps()
    print(f"\nMaps found: {len(maps)}")
    
    lua_files = list(Path("lua").rglob("*.lua")) if Path("lua").exists() else []
    print(f"Lua files: {len(lua_files)}")

def show_menu():
    """Main interactive menu"""
    maps = detect_maps()
    
    while True:
        clear_screen()
        print(f"\n{Colors.BOLD}{'='*50}{Colors.END}")
        print(f"{Colors.CYAN}{Colors.BOLD}     ARCADE ANOMALY - TEST MENU{Colors.END}")
        print(f"{Colors.BOLD}{'='*50}{Colors.END}\n")
        
        print("  1) Launch (select map)")
        print("  2) Launch Dev Mode (select map)")
        print("  3) Reinstall Addon")
        print("  4) Show Status")
        print("  5) Remove Addon")
        print()
        print("  0) Exit")
        print()
        
        try:
            choice = input("Select: ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\n\nGoodbye!")
            sys.exit(0)
        
        if choice == "1":
            check_gmod()
            map_name = select_map(maps)
            if map_name:
                install_addon()
                launch_gmod(map_name, dev_mode=False)
                input("\nPress Enter to continue...")
                # Refresh map list in case new maps downloaded
                maps = detect_maps()
        
        elif choice == "2":
            check_gmod()
            map_name = select_map(maps)
            if map_name:
                install_addon()
                launch_gmod(map_name, dev_mode=True)
                input("\nPress Enter to continue...")
                maps = detect_maps()
        
        elif choice == "3":
            check_gmod()
            install_addon()
            input("\nPress Enter to continue...")
        
        elif choice == "4":
            show_status()
            input("\nPress Enter to continue...")
        
        elif choice == "5":
            check_gmod()
            target = ADDONS_PATH / ADDON_NAME
            if target.exists() or target.is_symlink():
                if target.is_symlink():
                    target.unlink()
                else:
                    import shutil
                    shutil.rmtree(target)
                ok("Addon removed")
            else:
                warn("Addon not found")
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
    
    parser = argparse.ArgumentParser(description="Arcade Anomaly Test Launcher")
    parser.add_argument("command", nargs="?", default="menu",
                       help="Command: menu, install, remove, status, launch MAP, dev MAP, go, go-dev")
    parser.add_argument("map", nargs="?", help="Map name for launch/dev commands")
    
    args = parser.parse_args()
    
    if args.command == "menu" or args.command == "":
        show_menu()
    
    elif args.command == "install":
        check_gmod()
        install_addon()
    
    elif args.command == "remove":
        check_gmod()
        target = ADDONS_PATH / ADDON_NAME
        if target.exists() or target.is_symlink():
            if target.is_symlink():
                target.unlink()
            else:
                import shutil
                shutil.rmtree(target)
            ok("Removed")
    
    elif args.command == "status":
        show_status()
    
    elif args.command == "launch":
        check_gmod()
        install_addon()
        if args.map:
            launch_gmod(args.map, dev_mode=False)
    
    elif args.command == "dev":
        check_gmod()
        install_addon()
        if args.map:
            launch_gmod(args.map, dev_mode=True)
    
    elif args.command == "go":
        check_gmod()
        maps = detect_maps()
        map_name = select_map(maps)
        if map_name:
            install_addon()
            launch_gmod(map_name, dev_mode=False)
    
    elif args.command == "go-dev":
        check_gmod()
        maps = detect_maps()
        map_name = select_map(maps)
        if map_name:
            install_addon()
            launch_gmod(map_name, dev_mode=True)
    
    else:
        err(f"Unknown command: {args.command}")
        print("\nUsage:")
        print("  ./test_mod.py              - Interactive menu")
        print("  ./test_mod.py go           - Quick launch")
        print("  ./test_mod.py launch MAP   - Launch specific map")
        sys.exit(1)

if __name__ == "__main__":
    main()
