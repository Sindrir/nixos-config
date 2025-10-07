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
alias k="kubectl"
alias nurse="sudo nixos-rebuild switch --flake /home/sindreo/nixos-config#work-laptop"
alias furse="nix flake update --flake /home/sindreo/nixos-config"
alias ll="eza -l --icons --group-directories-first"
alias ls="eza --icons --group-directories-first"
alias tree="eza --tree --icons --group-directories-first"
zoxide init --cmd cd fish | source
starship init fish | source
direnv hook fish | source
jwt completion fish | source
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

string match -q "$TERM_PROGRAM" kiro and . (kiro --locate-shell-integration-path fish)
