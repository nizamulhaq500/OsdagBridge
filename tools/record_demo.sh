#!/bin/bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
cd "$DIR"

OUTPUT_VIDEO="/Users/nizam/internship/demo_screen_recording.mp4"
DURATION=125

echo "=========================================================="
echo "🎬 OsdagBridge Automated Screen Recording"
echo "Candidate: Nizam (nizamulhaq500)"
echo "Output: $OUTPUT_VIDEO"
echo "Duration: $DURATION seconds (~2 minutes)"
echo "=========================================================="
echo ""
echo "Starting in 3 seconds... Keep your desktop visible!"
sleep 1
echo "2..."
sleep 1
echo "1..."
sleep 1
echo "🎥 RECORDING STARTED!"

# Start ffmpeg in background capturing screen 3 (main Retina display)
/opt/homebrew/bin/ffmpeg -y -f avfoundation -framerate 30 -i "3" -t $DURATION -c:v libx264 -pix_fmt yuv420p "$OUTPUT_VIDEO" > /tmp/ffmpeg_record.log 2>&1 &
FFMPEG_PID=$!

echo "[INFO] ffmpeg recording running in background (PID: $FFMPEG_PID)"

# Run the automated UI demonstration with the active conda environment
QT_PLUGIN_PATH=/opt/anaconda3/envs/osdagbridge-env/lib/python3.12/site-packages/PySide6/Qt/plugins \
/opt/anaconda3/envs/osdagbridge-env/bin/python tools/auto_demo.py || true

echo "[INFO] UI demonstration finished. Waiting for video encoder to finalize..."
wait $FFMPEG_PID || true

echo ""
echo "=========================================================="
echo "✅ SUCCESS! Screen recording saved to:"
echo "   $OUTPUT_VIDEO"
echo "=========================================================="
