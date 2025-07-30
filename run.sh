#!/bin/bash

# run.sh - Runs the apartment monitoring script
# Usage: ./run.sh [URL] [INSTANCE_NAME]
# If no arguments provided, runs default monitoring instances

set -e  # Exit on any error

# Default URLs and instance names
DEFAULT_MONITORS=(
    "https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments|The Pier Apartments"
    "https://www.equityapartments.com/new-york-city/jersey-city/portside-towers-apartments|Portside Towers"
)

# Check arguments
if [ $# -eq 0 ]; then
    echo "🏠 Starting Default Apartment Monitors..."
    echo "========================================"
    echo "Will monitor:"
    echo "1. The Pier Apartments"
    echo "2. Portside Towers"
    echo ""
    RUN_DEFAULT=true
elif [ $# -eq 2 ]; then
    URL="$1"
    INSTANCE_NAME="$2"
    RUN_DEFAULT=false
else
    echo "Usage: $0 [URL] [INSTANCE_NAME]"
    echo ""
    echo "Examples:"
    echo "  $0  # Run default monitors (The Pier Apartments + Portside Towers)"
    echo "  $0 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments'"
    exit 1
fi

if [ "$RUN_DEFAULT" = false ]; then
    echo "🏠 Starting Single Apartment Monitor..."
    echo "======================================"
    echo "URL: $URL"
    echo "Instance: $INSTANCE_NAME"
    echo ""
fi

# Check if virtual environment exists
if [ ! -d "apartment_monitor_env" ]; then
    echo "❌ Virtual environment not found!"
    echo "Please run ./setup.sh first to set up the environment."
    exit 1
fi

# Check if credentials file exists
if [ ! -f "credentials" ]; then
    echo "❌ Credentials file not found!"
    echo "Please create a 'credentials' file with your Pushover credentials."
    echo "Line 1: Your Pushover User Key"
    echo "Line 2: Your Pushover App Token"
    exit 1
fi

# Check if credentials file has content (not just template)
if grep -q "YOUR_PUSHOVER" credentials; then
    echo "❌ Please update the credentials file with your actual Pushover credentials!"
    echo "Edit the 'credentials' file and replace the template values."
    exit 1
fi

# Check if main.py exists
if [ ! -f "main.py" ]; then
    echo "❌ main.py not found!"
    echo "Please ensure main.py is in the current directory."
    exit 1
fi

# Activate virtual environment
echo "⚡ Activating virtual environment..."
source apartment_monitor_env/bin/activate

# Check if required packages are installed
echo "🔍 Checking dependencies..."
python -c "import cloudscraper, bs4, apprise" 2>/dev/null || {
    echo "❌ Some dependencies are missing!"
    echo "Please run ./setup.sh to install dependencies."
    exit 1
}

echo "✅ All dependencies found!"
echo ""

# Run the monitoring script
if [ "$RUN_DEFAULT" = true ]; then
    echo "🚀 Starting default monitoring instances..."
    echo "Each monitor will run in the background"
    echo "Press Ctrl+C to stop all monitors"
    echo ""
    
    # Array to store background process PIDs
    PIDS=()
    
    # Start each default monitor in background
    for monitor in "${DEFAULT_MONITORS[@]}"; do
        IFS='|' read -r url instance_name <<< "$monitor"
        echo "Starting: $instance_name"
        python main.py "$url" "$instance_name" &
        PIDS+=($!)
    done
    
    echo ""
    echo "✅ All monitors started!"
    echo "Monitor PIDs: ${PIDS[*]}"
    echo ""
    echo "To check logs in real-time:"
    echo "  tail -f nohup.out"
    echo ""
    echo "To stop all monitors:"
    echo "  pkill -f 'python main.py'"
    echo ""
    
    # Wait for user interrupt
    trap 'echo ""; echo "🛑 Stopping all monitors..."; kill ${PIDS[@]} 2>/dev/null; exit 0' INT
    
    # Wait for all background processes
    wait
else
    echo "🚀 Starting single monitor..."
    echo "Press Ctrl+C to stop monitoring"
    echo ""
    
    python main.py "$URL" "$INSTANCE_NAME"
fi
