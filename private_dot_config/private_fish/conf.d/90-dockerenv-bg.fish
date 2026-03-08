if status is-interactive
    if test -f /.dockerenv -o -f /run/.containerenv
        printf '\e]11;#0f2d3a\a'

        function __dockerenv_restore_bg_on_exit --on-event fish_exit
            # Reset terminal background to its default (supported terminals).
            printf '\e]111\a'
            functions -e __dockerenv_restore_bg_on_exit
        end
    end
end
