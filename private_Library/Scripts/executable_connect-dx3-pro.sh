#!/bin/bash

# @tuna.title Connect DX3 Pro+
# @tuna.subtitle Connect to DX3 Pro+ over Bluetooth and switch system audio output to it.
# @tuna.icon symbol:headphones
# @tuna.mode inline
# @tuna.input none
# @tuna.output text

set -e

DEVICE_NAME="DX3 Pro+"
DEVICE_MAC="00-02-5b-00-ff-07"

export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if ! command -v blueutil >/dev/null 2>&1; then
    echo "Installing blueutil..."
    brew install blueutil >/dev/null
fi

if ! command -v SwitchAudioSource >/dev/null 2>&1; then
    echo "Installing switchaudio-osx..."
    brew install switchaudio-osx >/dev/null
fi

if [ "$(blueutil --is-connected "$DEVICE_MAC")" = "1" ]; then
    echo "Already connected. Switching audio output..."
else
    echo "Connecting to $DEVICE_NAME..."
    blueutil --connect "$DEVICE_MAC"

    for i in 1 2 3 4 5; do
        sleep 1
        if [ "$(blueutil --is-connected "$DEVICE_MAC")" = "1" ]; then
            break
        fi
    done

    if [ "$(blueutil --is-connected "$DEVICE_MAC")" != "1" ]; then
        echo "❌ Failed to connect to $DEVICE_NAME"
        exit 1
    fi
fi

sleep 2

CURRENT_OUTPUT="$(SwitchAudioSource -c -t output)"
if [ "$CURRENT_OUTPUT" = "$DEVICE_NAME" ]; then
    echo "✅ Connected — audio output: $DEVICE_NAME"
    exit 0
fi

if SwitchAudioSource -t output -s "$DEVICE_NAME" >/dev/null 2>&1; then
    echo "✅ Connected — switched audio output to $DEVICE_NAME"
else
    echo "⚠️  Connected but couldn't switch audio output (current: $CURRENT_OUTPUT)"
    exit 1
fi
