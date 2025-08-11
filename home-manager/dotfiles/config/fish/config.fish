if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias k="kubectl"
alias nurse="sudo nixos-rebuild switch --flake /home/sindreo/nixos-config#work-laptop"
alias furse="nix flake update --flake /home/sindreo/nixos-config"
alias ll="eza -l --icons --group-directories-first"
alias ls="eza --icons --group-directories-first"
alias tree="eza --tree --icons --group-directories-first"
zoxide init --cmd cd fish | source
starship init fish | source
direnv hook fish | source
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
