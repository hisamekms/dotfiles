function term_bg --description 'Set terminal background color with semantic keys'
    set -l choices reset focus deep calm success warn danger
    set -l key

    if test (count $argv) -eq 0
        if command -q fzf
            set -l picked (
                for entry in \
                    "reset|default|terminal default background" \
                    "focus|#0f172a|deep slate" \
                    "deep|#0b1020|night blue" \
                    "calm|#102a2a|calm teal" \
                    "success|#0f2e1f|forest green" \
                    "warn|#3a2a0f|amber brown" \
                    "danger|#3a1016|muted red"
                    set -l cols (string split '|' -- $entry)
                    set -l choice_key $cols[1]
                    set -l hex $cols[2]
                    set -l label $cols[3]

                    if test "$hex" = default
                        printf '%s\t%s\t-\t%s\n' $choice_key $hex $label
                    else
                        set -l swatch (set_color -b $hex)'   '(set_color normal)
                        printf '%s\t%s\t%s\t%s\n' $choice_key $hex $swatch $label
                    end
                end | fzf --ansi --delimiter '\t' --with-nth 1,2,3,4 --prompt 'term_bg> ' --height 50% --reverse
            )
            if test -z "$picked"
                return 0
            end
            set key (string split \t -- $picked)[1]
        else
            echo 'usage: term_bg <key>'
            echo 'keys: reset, list, focus, deep, calm, success, warn, danger'
            return 1
        end
    else
        set key $argv[1]
    end

    if test (count $argv) -gt 1
        echo 'usage: term_bg <key>'
        echo 'keys: reset, list, focus, deep, calm, success, warn, danger'
        return 1
    end

    switch $key
        case reset default
            # Reset to terminal default background.
            printf '\e]111\a'

        case list
            echo 'reset   -> terminal default background'
            echo 'focus   -> #0f172a (deep slate)'
            echo 'deep    -> #0b1020 (night blue)'
            echo 'calm    -> #102a2a (calm teal)'
            echo 'success -> #0f2e1f (forest green)'
            echo 'warn    -> #3a2a0f (amber brown)'
            echo 'danger  -> #3a1016 (muted red)'

        case focus
            printf '\e]11;#0f172a\a'

        case deep
            printf '\e]11;#0b1020\a'

        case calm
            printf '\e]11;#102a2a\a'

        case success
            printf '\e]11;#0f2e1f\a'

        case warn
            printf '\e]11;#3a2a0f\a'

        case danger
            printf '\e]11;#3a1016\a'

        case '*'
            echo "term_bg: unknown key '$key'"
            echo 'run `term_bg list` to see available keys'
            return 1
    end
end
