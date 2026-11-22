#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./tools/merge_audio.sh <path_to_voice_file>"
    echo "Example: ./tools/merge_audio.sh ~/Downloads/my_voice.m4a"
    exit 1
fi

VOICE_FILE="$1"
VIDEO_FILE="/Users/nizam/internship/demo_screen_recording.mp4"
FINAL_OUTPUT="/Users/nizam/internship/OsdagBridge_Final_Demo_Nizam.mp4"

if [ ! -f "$VIDEO_FILE" ]; then
    echo "Error: Video file $VIDEO_FILE not found! Please run ./tools/record_demo.sh first."
    exit 1
fi

if [ ! -f "$VOICE_FILE" ]; then
    echo "Error: Audio file $VOICE_FILE not found!"
    exit 1
fi

echo "Merging screen recording ($VIDEO_FILE) with your voiceover ($VOICE_FILE)..."

/opt/homebrew/bin/ffmpeg -y \
    -i "$VIDEO_FILE" \
    -i "$VOICE_FILE" \
    -c:v copy \
    -c:a aac -b:a 192k \
    -shortest \
    "$FINAL_OUTPUT"

echo ""
echo "=========================================================="
echo "🎉 COMPLETE! Your final video ready for YouTube is:"
echo "   $FINAL_OUTPUT"
echo "=========================================================="
