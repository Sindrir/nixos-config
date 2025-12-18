#!/usr/bin/env python3
"""
Convert AutoEQ APO ParametricEQ.txt files to Easy Effects JSON format
Usage: python apo-to-easyeffects.py input.txt output.json
"""

import sys
import json
import re

def parse_apo_file(filepath):
    """Parse APO ParametricEQ file and extract filter settings"""
    preamp = 0.0
    filters = []

    with open(filepath, 'r') as f:
        for line in f:
            line = line.strip()

            # Parse preamp
            if line.startswith('Preamp:'):
                match = re.search(r'(-?\d+\.?\d*)\s*dB', line)
                if match:
                    preamp = float(match.group(1))

            # Parse filter line
            # Format: Filter N: ON PK Fc XXX Hz Gain X.X dB Q X.XX
            if line.startswith('Filter') and 'ON' in line:
                parts = line.split()
                filter_data = {}

                for i, part in enumerate(parts):
                    if part == 'Fc' and i + 2 < len(parts):
                        filter_data['frequency'] = float(parts[i + 1])
                    elif part == 'Gain' and i + 2 < len(parts):
                        filter_data['gain'] = float(parts[i + 1])
                    elif part == 'Q' and i + 1 < len(parts):
                        filter_data['q'] = float(parts[i + 1])
                    elif part in ['PK', 'PEAK']:
                        filter_data['type'] = 'Bell'
                    elif part in ['LSC', 'LOW_SHELF']:
                        filter_data['type'] = 'Lo-shelf'
                    elif part in ['HSC', 'HIGH_SHELF']:
                        filter_data['type'] = 'Hi-shelf'

                if 'frequency' in filter_data and 'gain' in filter_data:
                    if 'q' not in filter_data:
                        filter_data['q'] = 1.0
                    if 'type' not in filter_data:
                        filter_data['type'] = 'Bell'
                    filters.append(filter_data)

    return preamp, filters

def create_easyeffects_preset(preamp, filters, preset_name="AutoEQ"):
    """Create Easy Effects JSON preset from parsed filters"""

    # Create band configurations
    bands = {}
    for i, f in enumerate(filters):
        bands[f"band{i}"] = {
            "frequency": f['frequency'],
            "gain": f['gain'],
            "mode": "APO (DR)",
            "mute": False,
            "q": f['q'],
            "slope": "x1",
            "solo": False,
            "type": f['type']
        }

    preset = {
        "output": {
            "blocklist": [],
            "equalizer#0": {
                "balance": 0.0,
                "bypass": False,
                "input-gain": preamp,
                "output-gain": 0.0,
                "pitch-left": 0.0,
                "pitch-right": 0.0,
                "split-channels": False,
                "mode": "APO (DR)",
                "num-bands": len(filters),
                **bands
            },
            "plugins_order": [
                "equalizer#0"
            ]
        }
    }

    return preset

def main():
    if len(sys.argv) != 3:
        print("Usage: python apo-to-easyeffects.py input.txt output.json")
        print("Example: python apo-to-easyeffects.py ParametricEQ.txt my-headphones.json")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    try:
        preamp, filters = parse_apo_file(input_file)

        print(f"Parsed {len(filters)} filters from {input_file}")
        print(f"Preamp: {preamp} dB")

        preset = create_easyeffects_preset(preamp, filters)

        with open(output_file, 'w') as f:
            json.dump(preset, f, indent=4)

        print(f"✓ Created Easy Effects preset: {output_file}")
        print(f"\nTo use:")
        print(f"1. Place {output_file} in ~/nixos-config/home-manager/dotfiles/config/easyeffects/output/")
        print(f"2. Rebuild NixOS: sudo nixos-rebuild switch --flake .#home-desktop")
        print(f"3. Open Easy Effects and select the preset")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
