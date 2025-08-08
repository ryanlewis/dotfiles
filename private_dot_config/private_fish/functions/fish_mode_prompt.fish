function fish_mode_prompt
    switch $fish_bind_mode
        case default
            echo -en "\e[1;31m[N]\e[0m "
        case insert
            echo -en "\e[1;32m[I]\e[0m "
        case replace_one
            echo -en "\e[1;33m[R]\e[0m "
        case visual
            echo -en "\e[1;35m[V]\e[0m "
        case '*'
            echo -en "\e[1;37m[?]\e[0m "
    end
end