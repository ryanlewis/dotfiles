#!/bin/bash

# @tuna.title Toggle Mouse Scroll Direction
# @tuna.subtitle Switch scroll direction between natural (iOS-style) and traditional (Windows-style)
# @tuna.icon symbol:computermouse.fill
# @tuna.mode inline
# @tuna.input none
# @tuna.output text

# Get current scroll direction setting (1 = natural, 0 = traditional)
current=$(defaults read -g com.apple.swipescrolldirection 2>/dev/null)

if [ "$current" = "1" ]; then
    # Currently natural scrolling, switch to traditional
    defaults write -g com.apple.swipescrolldirection -bool false
    echo "✅ Switched to Traditional Scrolling (Windows-style)"
else
    # Currently traditional scrolling or not set, switch to natural
    defaults write -g com.apple.swipescrolldirection -bool true
    echo "✅ Switched to Natural Scrolling (iOS-style)"
fi

# Note: You may need to log out and back in for the change to take effect
# Alternatively, you can restart the preference daemon
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
