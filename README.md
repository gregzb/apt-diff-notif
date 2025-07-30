# Apartment Monitor

A Python script that monitors apartment listings for changes and sends notifications via Pushover.

## Features

- 🏠 Monitors apartment availability on Equity Apartments websites
- 📱 Sends push notifications via Pushover when changes are detected
- 🔄 Automatically rotates scraper sessions to avoid detection
- ⏰ Randomized checking intervals to appear more human-like
- 🎯 Tracks both 1BR and 2BR units (configurable)

## Quick Setup (Fresh Digital Ocean Instance)

1. **Clone/download the files** to your server:
   ```bash
   # Upload main.py, setup.sh, run.sh to your server
   ```

2. **Run the setup script**:
   ```bash
   ./setup.sh
   ```
   This will:
   - Install Python 3 and required system packages
   - Create a virtual environment
   - Install all Python dependencies (cloudscraper, beautifulsoup4, apprise)
   - Create a credentials template

3. **Configure Pushover credentials**:
   ```bash
   nano credentials
   ```
   Replace the template with your actual Pushover credentials:
   ```
   YOUR_PUSHOVER_USER_KEY
   YOUR_PUSHOVER_APP_TOKEN
   ```

4. **Start monitoring**:
   ```bash
   ./run.sh
   ```
   This will start monitoring both default properties:
   - The Pier Apartments
   - Portside Towers

   **Background Options:**
   ```bash
   # Run in background (survives terminal close)
   ./run.sh --background
   
   # Run in screen sessions (interactive, survives terminal close)
   ./run.sh --screen
   ```

   Or monitor a specific property:
   ```bash
   ./run.sh 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments'
   
   # With background options
   ./run.sh 'URL' 'INSTANCE_NAME' --background
   ./run.sh 'URL' 'INSTANCE_NAME' --screen
   ```

## Usage

```bash
# Run default monitors (The Pier Apartments + Portside Towers)
./run.sh

# Run in background (survives terminal close)
./run.sh --background

# Run in screen sessions (interactive, survives terminal close)
./run.sh --screen

# Or monitor a specific property
./run.sh <URL> <INSTANCE_NAME>

# With background options
./run.sh <URL> <INSTANCE_NAME> --background
./run.sh <URL> <INSTANCE_NAME> --screen
```

**Parameters:**
- No parameters: Runs default monitors for both The Pier Apartments and Portside Towers
- `URL`: The Equity Apartments property URL to monitor
- `INSTANCE_NAME`: A friendly name for the property (appears in notifications)
- `--background` or `--bg`: Run in background using nohup (logs to apartment_monitor.log)
- `--screen`: Run in detached screen sessions (interactive, can reattach later)

**Examples:**
```bash
# Default monitoring (foreground)
./run.sh

# Default monitoring (background - survives terminal close)
./run.sh --background

# Default monitoring (screen sessions)
./run.sh --screen

# Custom property monitoring
./run.sh 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments'

# Custom property in background
./run.sh 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments' --background
```

## How It Works

1. **Monitoring Loop**: Checks for apartment changes every ~70 seconds (±20 seconds randomization)
2. **Scraper Rotation**: Creates new scraper sessions every ~10 minutes (±2 minutes randomization)
3. **Change Detection**: Compares current units with previous scan
4. **Notifications**: Sends detailed diff notifications via Pushover when changes detected

## Pushover Setup

1. Create a Pushover account at https://pushover.net/
2. Create an application to get your App Token
3. Find your User Key in your account settings
4. Add both to the `credentials` file

## Running in Background

The script now has built-in background options that survive terminal disconnection:

### Option 1: Background with nohup (Simple)
```bash
# Default monitors
./run.sh --background

# Custom property
./run.sh 'URL' 'INSTANCE_NAME' --background
```

**Features:**
- Runs in background, survives terminal close
- Logs to `apartment_monitor.log`
- Simple to use

**Management:**
```bash
# Check logs
tail -f apartment_monitor.log

# Stop all monitors
pkill -f "python main.py"
```

### Option 2: Screen sessions (Interactive)
```bash
# Default monitors (creates multiple screen sessions)
./run.sh --screen

# Custom property
./run.sh 'URL' 'INSTANCE_NAME' --screen
```

**Features:**
- Each monitor runs in its own screen session
- Can reattach to sessions for interactive monitoring
- Survives terminal close

**Management:**
```bash
# List all screen sessions
screen -list

# Attach to a specific monitor
screen -r apt_the_pier_apartments
screen -r apt_portside_towers

# Detach from session (while attached)
Ctrl+A, then D

# Stop all monitors
pkill -f "python main.py"
```

### Legacy Method (Manual nohup)
If you prefer the old manual approach:

```bash
# Default monitors
nohup ./run.sh > monitor.log 2>&1 &

# Custom property
nohup ./run.sh 'URL' 'INSTANCE_NAME' > monitor.log 2>&1 &
```

## Troubleshooting

- **Permission denied**: Run `chmod +x setup.sh run.sh`
- **Dependencies missing**: Re-run `./setup.sh`
- **Credentials error**: Check the `credentials` file format
- **No notifications**: Verify Pushover credentials and app setup

## Files

- `main.py` - Main monitoring script
- `setup.sh` - One-time setup script for fresh systems
- `run.sh` - Script to run the monitor with proper environment
- `credentials` - Pushover credentials (create after setup)
- `requirements.txt` - Python dependencies list
