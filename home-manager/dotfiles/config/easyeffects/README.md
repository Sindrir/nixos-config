# Easy Effects Configuration

This directory contains Easy Effects presets managed declaratively through NixOS.

## Default Preset

`output/default.json` - Contains a 10-band parametric equalizer with flat response (all gains at 0 dB).

## How to Use

1. After rebuilding NixOS, open Easy Effects
2. The preset will be available in **Presets → Output → default**
3. Enable the preset to activate the equalizer
4. Adjust EQ bands in the GUI or edit the JSON file directly

## Importing AutoEQ APO Profiles

AutoEQ provides headphone/speaker correction profiles. To import an APO profile:

### Method 1: Using Easy Effects GUI (Easiest)

1. Download an AutoEQ profile from https://github.com/jaakkopasanen/AutoEq
2. Look for the `ParametricEQ.txt` file in your headphone's folder
3. Open Easy Effects → Equalizer → Click the menu (⋮) → Import APO Preset
4. Select the `ParametricEQ.txt` file
5. Save your preset: Presets → Save → Enter a name

### Method 2: Manual Conversion to JSON

If you want to add the profile declaratively:

1. Download the `ParametricEQ.txt` file
2. Open it and note the filter settings (frequency, gain, Q)
3. Edit `output/your-preset.json` and update the band values
4. Commit to git and rebuild NixOS

### Example APO Format

```
Preamp: -6.0 dB
Filter 1: ON PK Fc 105 Hz Gain 6.0 dB Q 0.70
Filter 2: ON PK Fc 210 Hz Gain -2.5 dB Q 1.20
```

This translates to:
- Apply -6.0 dB preamp (input-gain: -6.0)
- Band at 105 Hz with +6.0 dB gain and Q=0.70
- Band at 210 Hz with -2.5 dB gain and Q=1.20

## Creating New Presets

1. Copy `output/default.json` to `output/my-preset.json`
2. Edit the JSON file with your desired settings
3. Rebuild NixOS: `cd ~/nixos-config && sudo nixos-rebuild switch --flake .#home-desktop`
4. The preset will appear in Easy Effects

## Adjusting EQ Bands

Edit the JSON file and modify:
- `frequency`: Center frequency in Hz
- `gain`: dB boost/cut (positive = boost, negative = cut)
- `q`: Q factor (bandwidth - higher = narrower)
- `type`: "Bell", "Hi-pass", "Lo-pass", "Hi-shelf", "Lo-shelf", etc.

Example for bass boost:
```json
"band0": {
    "frequency": 60.0,
    "gain": 3.5,
    "q": 1.0,
    "type": "Bell"
}
```

## Tips

- Start with small gain adjustments (±3 dB)
- Use higher Q (2.0-5.0) for surgical cuts
- Use lower Q (0.5-1.0) for broad tonal shaping
- Apply negative preamp if you boost multiple bands (prevents clipping)
- Test with music you know well
