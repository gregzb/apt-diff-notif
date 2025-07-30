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

   Or monitor a specific property:
   ```bash
   ./run.sh 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments'
   ```

## Usage

```bash
# Run default monitors (The Pier Apartments + Portside Towers)
./run.sh

# Or monitor a specific property
./run.sh <URL> <INSTANCE_NAME>
```

**Parameters:**
- No parameters: Runs default monitors for both The Pier Apartments and Portside Towers
- `URL`: The Equity Apartments property URL to monitor
- `INSTANCE_NAME`: A friendly name for the property (appears in notifications)

**Examples:**
```bash
# Default monitoring (recommended)
./run.sh

# Custom property monitoring
./run.sh 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments'
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

To run the monitors in the background (survives SSH disconnection):

```bash
# Default monitors
nohup ./run.sh > monitor.log 2>&1 &

# Custom property
nohup ./run.sh 'URL' 'INSTANCE_NAME' > monitor.log 2>&1 &
```

Check the log:
```bash
tail -f monitor.log
```

Stop the background process:
```bash
pkill -f "python main.py"
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
