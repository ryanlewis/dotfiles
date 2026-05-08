function fish_mode_prompt
    switch $fish_bind_mode
        case default
            echo -en "\e[1;31m\xef\x80\xa3\e[0m  "
        case insert
            echo -en "\e[1;32m\xef\x81\x80\e[0m  "
        case replace_one
            echo -en "\e[1;33m\xef\x80\xa1\e[0m  "
        case visual
            echo -en "\e[1;35m\xef\x81\xae\e[0m  "
        case '*'
            echo -en "\e[1;37m?\e[0m  "
    end
end
