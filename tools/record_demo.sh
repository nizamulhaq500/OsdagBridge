#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

OUTPUT_VIDEO="/Users/nizam/internship/demo_screen_recording.mp4"
DURATION=128

echo "=========================================================="
echo "🎬 OsdagBridge Automated Screen Recording"
echo "Candidate: Nizam (nizamulhaq500)"
echo "Output: $OUTPUT_VIDEO"
echo "Duration: ~2 minutes"
echo "=========================================================="
echo ""

# Find Retina screen device index dynamically
SCREEN_DEV=$(/opt/homebrew/bin/ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -i "Capture screen 0" | head -n 1 | sed -E 's/.*\[([0-9]+)\].*/\1/')
if [ -z "$SCREEN_DEV" ]; then
    SCREEN_DEV="3"
fi
echo "[INFO] Using avfoundation screen device index: $SCREEN_DEV"

echo "Starting in 3 seconds... Keep your desktop visible!"
sleep 1
echo "2..."
sleep 1
echo "1..."
sleep 1
echo "🎥 RECORDING STARTED!"

# Start ffmpeg in background capturing screen
/opt/homebrew/bin/ffmpeg -y -f avfoundation -framerate 30 -i "$SCREEN_DEV" -t $DURATION -c:v libx264 -pix_fmt yuv420p "$OUTPUT_VIDEO" > /tmp/ffmpeg_record.log 2>&1 &
FFMPEG_PID=$!

echo "[INFO] ffmpeg recording running in background (PID: $FFMPEG_PID)"

cleanup() {
    if kill -0 $FFMPEG_PID 2>/dev/null; then
        echo "[INFO] Stopping ffmpeg recording..."
        kill -INT $FFMPEG_PID 2>/dev/null || true
        wait $FFMPEG_PID 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Run the automated UI demonstration with the active conda environment
QT_PLUGIN_PATH=/opt/anaconda3/envs/osdagbridge-env/lib/python3.12/site-packages/PySide6/Qt/plugins \
/opt/anaconda3/envs/osdagbridge-env/bin/python tools/auto_demo.py

echo "[INFO] UI demonstration finished. Finalizing video encoding..."
wait $FFMPEG_PID 2>/dev/null || true

echo ""
echo "=========================================================="
echo "✅ SUCCESS! Screen recording saved to:"
echo "   $OUTPUT_VIDEO"
echo "   File Size: $(ls -lh "$OUTPUT_VIDEO" | awk '{print $5}')"
echo "=========================================================="
