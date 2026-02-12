# The Link Whisperer

A custom URL dispatcher for NixOS that intercepts link clicks and routes them to the right handler. Currently supports JetBrains Code With Me — everything else falls through to your default browser.

## What it does

When registered as the default URL handler:
- `code-with-me.global.jetbrains.com/*` links launch the Code With Me client via `steam-run`
- All other URLs open in Firefox (or `$BROWSER` if set)

The included `join_code_with_me` fish function can also be used directly from the terminal. It accepts a URL, a session ID, or reads from your clipboard (primary selection first, then Ctrl+C).

## Setup

Import the home-manager module and enable it:

```nix
# flake.nix — add to sharedModules or modules
./packages/link-whisperer/hm-module.nix

# your home-manager config
programs.link-whisperer.enable = true;
```

That's it. The module handles everything:
- Installs the package and all runtime dependencies
- Registers as the default handler for `http`/`https` URLs
- Adds fish shell aliases (`cwm`, `jetbrains-join`, `jbcwm`)

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `enable` | bool | `false` | Enable The Link Whisperer |
| `setAsDefaultBrowser` | bool | `true` | Register as default URL handler |
| `fishAliases` | list of str | `["cwm" "jetbrains-join" "jbcwm"]` | Fish aliases for `join_code_with_me` |

## Usage

```bash
# From terminal (all equivalent)
cwm https://code-with-me.global.jetbrains.com/pRM5I_gYHnbnvNr22LgqDA
cwm pRM5I_gYHnbnvNr22LgqDA

# With clipboard (select or copy a URL, then run without args)
cwm
```

Desktop notifications are shown for both successful launches and errors (expired sessions, download failures).

## Runtime dependencies

Installed automatically by the home-manager module:

| Package | Purpose |
|---|---|
| `wl-clipboard` | Clipboard access via `wl-paste` |
| `libnotify` | Desktop notifications via `notify-send` |
| `steam-run` | FHS environment for the JetBrains client |
| `wget` | Downloading the CWM launcher script |

## Adding new URL handlers

Edit the case statement in `default.nix` to route additional URL patterns:

```bash
case "$URL" in
  *code-with-me.global.jetbrains.com/*)
    exec fish -c "join_code_with_me '$URL'"
    ;;
  *meet.google.com/*)
    exec some-other-handler "$URL"
    ;;
  *)
    exec ${BROWSER:-firefox} "$URL"
    ;;
esac
```

## Files

```
packages/link-whisperer/
├── default.nix              # Nix package derivation
├── hm-module.nix            # Home-manager module
├── join_code_with_me.fish   # Fish function + completions
├── icon-full.png            # Full resolution icon
├── icon-256.png             # 256x256 icon
├── icon-128.png             # 128x128 icon
└── README.md
```
