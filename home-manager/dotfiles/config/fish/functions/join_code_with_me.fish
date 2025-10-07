complete -c join_code_with_me -f -a "https://code-with-me.global.jetbrains.com/\<session_id\>" -d "Code With Me session URL"
complete -c join_code_with_me -f -a "\<session_id\>" -d "Code With Me session ID"

function join_code_with_me
    if test (count $argv) -eq 0
        echo "Error: No URL or session ID provided."
        return 1
    end

    set input $argv[1]
    if string match -r '^https?://code-with-me\.global\.jetbrains\.com/(?<session_id>[A-Za-z0-9]+)' $input
        string match -r 'code-with-me\.global\.jetbrains\.com/(?<session_id>[A-Za-z0-9]+)' $input
    else
        set session_id $input
    end
    steam-run bash -c "$(wget -nv -O- "https://code-with-me.global.jetbrains.com/$session_id/cwm-client-launcher-linux.sh?arch_type=$(uname -m)")"
end
