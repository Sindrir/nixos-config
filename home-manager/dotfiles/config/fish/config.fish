if status is-interactive
    # Commands to run in interactive sessions can go here
end
function ne
    $EDITOR ~/nixos-config
end
function ni
    set tag (count $argv) >/dev/null; and set tag $argv[1]; or set tag '<HOME>'
    grep -n "$tag" ~/nixos-config/home-manager/common.nix | grep -o -P '\d+' | xargs -I % $EDITOR +% ~/nixos-config/home-manager/common.nix
end
complete -c ni --no-files -a "(sed -n '/packages = with pkgs; \[/,/^\s*];/p' ~/nixos-config/home-manager/common.nix | grep '^\s*#' | sed 's/#//g; s/^\s*//')"
function k --wraps=kubecolor
    set -l ns (command kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)
    if test -n "$ns"
        kubecolor --as="$ns" $argv
    else
        kubecolor $argv
    end
end
alias kubectl="kubecolor"
function plaude --wraps=claude
    mkdir -p ~/.claude-personal
    # Use a personal-specific settings file that excludes work-account OAuth MCPs
    set personal_settings ~/.claude-personal/settings.json
    if not test -f $personal_settings; or test -L $personal_settings
        # Generate settings without the atlassian HTTP OAuth MCP (tied to work account)
        python3 -c "
import json, sys
d = json.load(open(\"$HOME/.claude/settings.json\"))
d.setdefault('mcpServers', {}).pop('atlassian', None)
json.dump(d, sys.stdout, indent=2)
" > $personal_settings
    end
    set -x CLAUDE_CONFIG_DIR ~/.claude-personal
    claude $argv
end

function nurse-fix
    nixpkgs-fmt /home/sindreo/nixos-config
    statix fix /home/sindreo/nixos-config
    deadnix -e /home/sindreo/nixos-config
end
function nurse
    sudo -v
    set -l flake_dir /home/sindreo/nixos-config
    if test -n "(git -C $flake_dir status --porcelain)"
        set_color -o yellow
        echo -n "warning:" >&2
        set_color normal
        echo " Git tree '$flake_dir' is dirty" >&2
    end
    if not nix --option warn-dirty false flake check $flake_dir
        echo "Use `nurse-fix` to automatically fix issues."
        return 1
    end
    sudo nixos-rebuild switch --impure --option warn-dirty false --flake $flake_dir#(hostname)
end
alias qnurse="sudo nixos-rebuild switch --impure --flake /home/sindreo/nixos-config#(hostname)"
alias furse="nix flake update --flake /home/sindreo/nixos-config"
alias ll="eza -l --icons --group-directories-first"
alias ls="eza --icons --group-directories-first"
alias tree="eza --tree --icons --group-directories-first"
alias du="dust"
alias df="duf"
alias ps="procs"
function fish_command_not_found
    command-not-found $argv
end

zoxide init --cmd cd fish | source
fzf --fish | source
atuin init fish | source
pay-respects init fish | source
starship init fish | source
direnv hook fish | source
jwt completion fish | source
function y --wraps=yazi
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

string match -q "$TERM_PROGRAM" kiro and . (kiro --locate-shell-integration-path fish)

alias pt="presenterm"
function ptit
    setsid kitty -o font_size=24 presenterm ~/Documents/itPresentation/it.md -t nb &>/dev/null &
    disown
end
