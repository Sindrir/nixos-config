complete -c join_code_with_me -f -a "https://code-with-me.global.jetbrains.com/\<session_id\>" -d "Code With Me session URL"
complete -c join_code_with_me -f -a "\<session_id\>" -d "Code With Me session ID"

function join_code_with_me
    if test (count $argv) -eq 0
        set input (wl-paste --primary 2>/dev/null)
        if test -z "$input"
            set input (wl-paste 2>/dev/null)
        end
        if test -z "$input"
            echo "Error: No argument provided and clipboard is empty."
            return 1
        end
        echo "Using clipboard: $input"
    else
        set input $argv[1]
    end
    if not string match -rq '^https?://code-with-me\.global\.jetbrains\.com/(?<session_id>[A-Za-z0-9_-]+)' $input
        set session_id $input
    end
    set -l script_url "https://code-with-me.global.jetbrains.com/$session_id/cwm-client-launcher-linux.sh"

    notify-send -a "Code With Me" -t 10000 -i dialog-information "Code With Me" "Joining session $session_id..."
    steam-run bash -c "SCRIPT=\$(wget -nv -O- '$script_url') || exit 1; bash -c \"\$SCRIPT\""
    if test $status -ne 0
        notify-send -a "Code With Me" -t 10000 -u critical -i dialog-error "Code With Me" "Failed to launch Code With Me. The session may have expired."
    end
end
