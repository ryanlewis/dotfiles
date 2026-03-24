#!/bin/sh
# Battery indicator for tmux — shows when on battery power, hidden when plugged in

case "$(uname -s)" in
    Darwin)
        batt=$(pmset -g batt 2>/dev/null) || exit 0
        echo "$batt" | grep -q "'Battery Power'" || exit 0
        pct=$(echo "$batt" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
        ;;
    Linux)
        [ -r /sys/class/power_supply/BAT0/capacity ] || exit 0
        status=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
        [ "$status" = "Discharging" ] || exit 0
        pct=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        ;;
    *)
        exit 0
        ;;
esac

[ -z "$pct" ] && exit 0

# Nerd Font battery icons (FontAwesome): F240-F244
if [ "$pct" -ge 75 ]; then
    icon=$(printf '\xef\x89\x80')   # U+F240 battery-full
elif [ "$pct" -ge 50 ]; then
    icon=$(printf '\xef\x89\x81')   # U+F241 battery-three-quarters
elif [ "$pct" -ge 25 ]; then
    icon=$(printf '\xef\x89\x82')   # U+F242 battery-half
elif [ "$pct" -ge 10 ]; then
    icon=$(printf '\xef\x89\x83')   # U+F243 battery-quarter
else
    icon=$(printf '\xef\x89\x84')   # U+F244 battery-empty
fi

printf ' %s %d%% ' "$icon" "$pct"
