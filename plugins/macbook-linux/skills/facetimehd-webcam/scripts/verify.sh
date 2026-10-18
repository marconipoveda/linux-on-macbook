#!/bin/bash
# Normal user: grab a test frame and check PipeWire sees the camera.
# Usage: bash verify.sh [output.jpg]
OUT="${1:-$HOME/facetimehd-test.jpg}"
v4l2-ctl --list-devices 2>/dev/null || echo "(install v4l-utils for details)"
v4l2-ctl -d /dev/video0 --list-formats-ext 2>/dev/null | head -20
if command -v gst-launch-1.0 >/dev/null; then
  # The first frames are dark while auto-exposure settles, so skip ahead
  gst-launch-1.0 -q v4l2src device=/dev/video0 num-buffers=60 ! videoconvert ! jpegenc snapshot=true ! filesink location="$OUT" \
    && echo "Test frame: $OUT"
else
  echo "gst-launch-1.0 not found (gstreamer1.0-tools); test in a browser instead"
fi
command -v wpctl >/dev/null && wpctl status | sed -n '/Video/,/Settings/p'
