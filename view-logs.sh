#!/bin/bash

# Script to view ImageMate logs in real-time
# Usage: ./view-logs.sh

echo "📋 Viewing ImageMate logs..."
echo "Press Ctrl+C to stop"
echo "---"

# Clear any old logs and start fresh
log stream --predicate 'subsystem == "com.primattek.ImageMate"' --level debug --style compact
