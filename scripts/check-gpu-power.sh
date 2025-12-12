#!/usr/bin/env bash

# GPU Power Management Diagnostics Script
# For NixOS with NVIDIA Optimus and system76-power runtime PM

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Symbols
CHECK="${GREEN}✓${NC}"
CROSS="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"
INFO="${BLUE}ℹ${NC}"

echo -e "${BLUE}=== GPU Power Management Diagnostics ===${NC}\n"

# 1. Check graphics mode
echo -e "${BLUE}1. Graphics Mode:${NC}"
GRAPHICS_MODE=$(system76-power graphics 2>/dev/null || echo "unknown")
echo -e "   Current mode: ${YELLOW}$GRAPHICS_MODE${NC}"
if [ "$GRAPHICS_MODE" = "hybrid" ]; then
    echo -e "   $CHECK Hybrid mode active (correct for runtime PM)"
elif [ "$GRAPHICS_MODE" = "nvidia" ]; then
    echo -e "   $WARN NVIDIA mode - switch to hybrid for runtime PM"
    echo -e "   ${INFO} Run: sudo system76-power graphics hybrid && sudo reboot"
elif [ "$GRAPHICS_MODE" = "integrated" ]; then
    echo -e "   $WARN Integrated mode - dGPU disabled entirely"
else
    echo -e "   $CROSS Unknown mode"
fi
echo ""

# 2. Check AC adapter state
echo -e "${BLUE}2. AC Adapter State:${NC}"
AC_STATE="unknown"
AC_PATH=""
for ac_path in /sys/class/power_supply/AC /sys/class/power_supply/AC0 /sys/class/power_supply/ACAD; do
  if [ -e "$ac_path/online" ]; then
    AC_STATE=$(cat "$ac_path/online")
    AC_PATH="$ac_path"
    break
  fi
done

if [ "$AC_STATE" = "1" ]; then
    echo -e "   ${GREEN}PLUGGED IN${NC} (AC connected)"
    EXPECTED_GPU_STATE="on or active"
elif [ "$AC_STATE" = "0" ]; then
    echo -e "   ${YELLOW}ON BATTERY${NC} (AC disconnected)"
    EXPECTED_GPU_STATE="suspended"
else
    echo -e "   ${RED}Unknown AC state${NC}"
    EXPECTED_GPU_STATE="unknown"
fi
echo ""

# 3. Check power profile
echo -e "${BLUE}3. Power Profile:${NC}"
PROFILE=$(system76-power profile 2>/dev/null | head -n1 || echo "unknown")
echo -e "   $PROFILE"
echo ""

# 4. Check GPU PCI power state
echo -e "${BLUE}4. NVIDIA GPU Power State:${NC}"
GPU_PCI_PATH="/sys/bus/pci/devices/0000:01:00.0"

if [ -e "$GPU_PCI_PATH/power/runtime_status" ]; then
    GPU_RUNTIME_STATUS=$(cat "$GPU_PCI_PATH/power/runtime_status")
    GPU_POWER_CONTROL=$(cat "$GPU_PCI_PATH/power/control")

    echo -e "   Runtime Status: ${YELLOW}$GPU_RUNTIME_STATUS${NC}"
    echo -e "   Power Control:  ${YELLOW}$GPU_POWER_CONTROL${NC}"

    # Evaluate if state is correct
    if [ "$AC_STATE" = "0" ]; then
        # On battery - GPU should be suspended
        if [ "$GPU_RUNTIME_STATUS" = "suspended" ]; then
            echo -e "   $CHECK GPU is powered off (excellent for battery life)"
        else
            echo -e "   $CROSS GPU is still active on battery (will drain battery)"
            echo -e "   ${INFO} Expected: suspended, Got: $GPU_RUNTIME_STATUS"
        fi
    elif [ "$AC_STATE" = "1" ]; then
        # On AC - GPU can be active or suspended (both OK)
        if [ "$GPU_RUNTIME_STATUS" = "suspended" ]; then
            echo -e "   $CHECK GPU is suspended (will wake on-demand)"
        else
            echo -e "   $CHECK GPU is active (available for use)"
        fi
    fi

    # Check power control setting
    if [ "$GPU_POWER_CONTROL" = "auto" ]; then
        echo -e "   $CHECK Runtime PM enabled (control=auto)"
    elif [ "$GPU_POWER_CONTROL" = "on" ]; then
        if [ "$AC_STATE" = "1" ]; then
            echo -e "   $CHECK Runtime PM disabled on AC (control=on)"
        else
            echo -e "   $WARN Runtime PM disabled on battery (control=on)"
            echo -e "   ${INFO} GPU won't auto-suspend"
        fi
    fi
else
    echo -e "   $CROSS GPU PCI device not found at $GPU_PCI_PATH"
fi
echo ""

# 5. Check NVIDIA driver runtime PM capabilities
echo -e "${BLUE}5. NVIDIA Driver Runtime PM:${NC}"
if [ -e /proc/driver/nvidia/gpus/*/power ]; then
    D3_STATUS=$(grep "Runtime D3 status" /proc/driver/nvidia/gpus/*/power | awk -F: '{print $2}' | xargs)
    echo -e "   Runtime D3: ${YELLOW}$D3_STATUS${NC}"
    if [[ "$D3_STATUS" == *"Enabled"* ]]; then
        echo -e "   $CHECK Runtime D3 power management supported"
    else
        echo -e "   $CROSS Runtime D3 not enabled"
    fi
else
    echo -e "   $WARN NVIDIA driver not loaded or no GPU info available"
fi
echo ""

# 6. Check loaded NVIDIA modules
echo -e "${BLUE}6. NVIDIA Kernel Modules:${NC}"
NVIDIA_MODULES=$(lsmod | grep nvidia || true)
if [ -n "$NVIDIA_MODULES" ]; then
    echo "$NVIDIA_MODULES" | while read -r line; do
        MODULE=$(echo "$line" | awk '{print $1}')
        USED_BY=$(echo "$line" | awk '{print $3}')
        echo -e "   ${GREEN}$MODULE${NC} (used by $USED_BY modules)"
    done

    if [ "$AC_STATE" = "0" ] && [ "$GPU_RUNTIME_STATUS" = "suspended" ]; then
        echo -e "   ${INFO} Modules loaded but GPU suspended (using runtime PM)"
    elif [ "$AC_STATE" = "0" ] && [ "$GPU_RUNTIME_STATUS" != "suspended" ]; then
        echo -e "   $WARN Modules loaded and GPU active on battery"
        echo -e "   ${INFO} Consider unloading modules to force suspend"
    fi
else
    echo -e "   ${YELLOW}No NVIDIA modules loaded${NC}"
    if [ "$GPU_RUNTIME_STATUS" = "suspended" ]; then
        echo -e "   $CHECK GPU powered off without modules (good for battery)"
    fi
fi
echo ""

# 7. Check active GPU processes
echo -e "${BLUE}7. GPU Usage:${NC}"
if command -v nvidia-smi &> /dev/null; then
    if nvidia-smi --query-compute-apps=pid,process_name --format=csv,noheader 2>/dev/null | grep -q .; then
        echo -e "   ${YELLOW}Active GPU processes:${NC}"
        nvidia-smi --query-compute-apps=pid,process_name --format=csv,noheader 2>/dev/null || echo "   None"
    else
        if [ "$GPU_RUNTIME_STATUS" = "active" ]; then
            echo -e "   $CHECK No compute processes (GPU idle)"
        else
            echo -e "   $CHECK GPU powered off (no processes)"
        fi
    fi
else
    echo -e "   ${YELLOW}nvidia-smi not available${NC}"
fi
echo ""

# 8. Check recent power switch events
echo -e "${BLUE}8. Recent Power Switch Events:${NC}"
RECENT_LOGS=$(journalctl -u system76-power-switch.service -n 3 --no-pager --since "5 minutes ago" 2>/dev/null || echo "")
if [ -n "$RECENT_LOGS" ]; then
    echo "$RECENT_LOGS" | grep -E "(AC adapter|Battery mode|GPU)" || echo "   No recent events"
else
    echo "   No recent logs found"
fi
echo ""

# Summary
echo -e "${BLUE}=== Summary ===${NC}"
if [ "$AC_STATE" = "0" ]; then
    # On battery
    if [ "$GPU_RUNTIME_STATUS" = "suspended" ]; then
        echo -e "$CHECK ${GREEN}EXCELLENT:${NC} On battery with GPU suspended"
        echo -e "   Battery life is optimized"
    else
        echo -e "$CROSS ${RED}ISSUE:${NC} On battery but GPU is still active"
        echo -e "   ${INFO} Recommendations:"
        echo -e "   1. Ensure graphics mode is 'hybrid': sudo system76-power graphics hybrid"
        echo -e "   2. Ensure NVIDIA power management enabled in config"
        echo -e "   3. Rebuild and reboot: sudo nixos-rebuild switch --flake .#work-laptop && sudo reboot"
        echo -e "   4. After reboot, unplug AC and wait 5 seconds, then check again"
    fi
elif [ "$AC_STATE" = "1" ]; then
    # On AC
    echo -e "$CHECK ${GREEN}OK:${NC} On AC power"
    if [ "$GPU_RUNTIME_STATUS" = "suspended" ]; then
        echo -e "   GPU suspended (will wake on-demand with nvidia-offload)"
    else
        echo -e "   GPU active and available for use"
    fi
fi

echo ""
echo -e "${BLUE}=== Quick Actions ===${NC}"
echo -e "View live logs:        ${YELLOW}journalctl -u system76-power-switch.service -f${NC}"
echo -e "Manual GPU suspend:    ${YELLOW}echo auto | sudo tee $GPU_PCI_PATH/power/control${NC}"
echo -e "Manual GPU wake:       ${YELLOW}echo on | sudo tee $GPU_PCI_PATH/power/control${NC}"
echo -e "Run app on dGPU:       ${YELLOW}nvidia-offload <command>${NC}"
echo -e "Check GPU processes:   ${YELLOW}nvidia-smi${NC}"
echo ""
