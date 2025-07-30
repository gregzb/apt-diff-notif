#!/bin/bash

# run.sh - Runs the apartment monitoring script
# Usage: ./run.sh [URL] [INSTANCE_NAME] [--background|--screen]
# If no arguments provided, runs default monitoring instances

set -e  # Exit on any error

# Parse command line options
BACKGROUND_MODE=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --background|--bg)
            BACKGROUND_MODE="nohup"
            shift
            ;;
        --screen)
            BACKGROUND_MODE="screen"
            shift
            ;;
        *)
            ARGS+=("$1")
            shift
            ;;
    esac
done

# Restore positional parameters
set -- "${ARGS[@]}"

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
    echo "Usage: $0 [URL] [INSTANCE_NAME] [--background|--screen]"
    echo ""
    echo "Background Options:"
    echo "  --background, --bg    Run in background with nohup (survives terminal close)"
    echo "  --screen             Run in detached screen session"
    echo ""
    echo "Examples:"
    echo "  $0  # Run default monitors (The Pier Apartments + Portside Towers)"
    echo "  $0 --background  # Run default monitors in background"
    echo "  $0 --screen     # Run default monitors in screen session"
    echo "  $0 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments'"
    echo "  $0 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments' --background"
    exit 1
fi

if [ "$RUN_DEFAULT" = false ]; then
    echo "🏠 Starting Single Apartment Monitor..."
    echo "======================================"
    echo "URL: $URL"
    echo "Instance: $INSTANCE_NAME"
    echo ""
fi

# Check if screen is available for screen mode
if [ "$BACKGROUND_MODE" = "screen" ]; then
    if ! command -v screen &> /dev/null; then
        echo "❌ screen is not installed!"
        echo "Install it with: sudo apt install screen"
        echo "Or use --background mode instead"
        exit 1
    fi
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
    if [ "$BACKGROUND_MODE" = "nohup" ]; then
        echo "🚀 Starting default monitoring instances in background..."
        echo "Logs will be written to apartment_monitor.log"
        echo ""
        
        # Start each default monitor in background with nohup
        for monitor in "${DEFAULT_MONITORS[@]}"; do
            IFS='|' read -r url instance_name <<< "$monitor"
            echo "Starting: $instance_name (background)"
            nohup python main.py "$url" "$instance_name" >> apartment_monitor.log 2>&1 &
        done
        
        echo ""
        echo "✅ All monitors started in background!"
        echo ""
        echo "To check logs:"
        echo "  tail -f apartment_monitor.log"
        echo ""
        echo "To stop all monitors:"
        echo "  pkill -f 'python main.py'"
        echo ""
        echo "You can now safely close this terminal."
        
    elif [ "$BACKGROUND_MODE" = "screen" ]; then
        echo "🚀 Starting default monitoring instances in screen sessions..."
        echo ""
        
        # Start each default monitor in separate screen sessions
        for monitor in "${DEFAULT_MONITORS[@]}"; do
            IFS='|' read -r url instance_name <<< "$monitor"
            # Create screen session name from instance name (replace spaces with underscores)
            session_name="apt_$(echo "$instance_name" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
            echo "Starting: $instance_name (screen session: $session_name)"
            screen -dmS "$session_name" bash -c "source apartment_monitor_env/bin/activate && python main.py '$url' '$instance_name'"
        done
        
        echo ""
        echo "✅ All monitors started in screen sessions!"
        echo ""
        echo "To list screen sessions:"
        echo "  screen -list"
        echo ""
        echo "To attach to a session:"
        echo "  screen -r apt_the_pier_apartments    # For The Pier Apartments"
        echo "  screen -r apt_portside_towers        # For Portside Towers"
        echo ""
        echo "To detach from a session: Ctrl+A, then D"
        echo ""
        echo "To stop all monitors:"
        echo "  pkill -f 'python main.py'"
        echo ""
        echo "You can now safely close this terminal."
        
    else
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
    fi
else
    if [ "$BACKGROUND_MODE" = "nohup" ]; then
        echo "🚀 Starting single monitor in background..."
        echo "Logs will be written to apartment_monitor.log"
        echo ""
        
        nohup python main.py "$URL" "$INSTANCE_NAME" >> apartment_monitor.log 2>&1 &
        
        echo "✅ Monitor started in background!"
        echo ""
        echo "To check logs:"
        echo "  tail -f apartment_monitor.log"
        echo ""
        echo "To stop the monitor:"
        echo "  pkill -f 'python main.py'"
        echo ""
        echo "You can now safely close this terminal."
        
    elif [ "$BACKGROUND_MODE" = "screen" ]; then
        echo "🚀 Starting single monitor in screen session..."
        echo ""
        
        # Create screen session name from instance name
        session_name="apt_$(echo "$INSTANCE_NAME" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
        echo "Starting: $INSTANCE_NAME (screen session: $session_name)"
        screen -dmS "$session_name" bash -c "source apartment_monitor_env/bin/activate && python main.py '$URL' '$INSTANCE_NAME'"
        
        echo ""
        echo "✅ Monitor started in screen session!"
        echo ""
        echo "To attach to the session:"
        echo "  screen -r $session_name"
        echo ""
        echo "To detach from a session: Ctrl+A, then D"
        echo ""
        echo "To stop the monitor:"
        echo "  pkill -f 'python main.py'"
        echo ""
        echo "You can now safely close this terminal."
        
    else
        echo "🚀 Starting single monitor..."
        echo "Press Ctrl+C to stop monitoring"
        echo ""
        
        python main.py "$URL" "$INSTANCE_NAME"
    fi
fi
