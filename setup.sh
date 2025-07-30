#!/bin/bash

# setup.sh - Sets up the apartment monitoring environment from scratch
# Designed for fresh Ubuntu/Debian systems (like Digital Ocean droplets)

set -e  # Exit on any error

echo "🏠 Setting up Apartment Monitoring System..."
echo "============================================"

# Update system packages
echo "📦 Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install Python 3 and pip if not already installed
echo "🐍 Installing Python 3 and pip..."
sudo apt install -y python3 python3-pip python3-venv python3-dev

# Install additional system dependencies that might be needed
echo "🔧 Installing system dependencies..."
sudo apt install -y curl wget git build-essential libssl-dev libffi-dev

# Create virtual environment
echo "🌍 Creating Python virtual environment..."
python3 -m venv apartment_monitor_env

# Activate virtual environment
echo "⚡ Activating virtual environment..."
source apartment_monitor_env/bin/activate

# Upgrade pip in virtual environment
echo "📈 Upgrading pip..."
pip install --upgrade pip

# Install Python dependencies
echo "📚 Installing Python packages..."
pip install cloudscraper beautifulsoup4 apprise

# Create credentials template if it doesn't exist
if [ ! -f "credentials" ]; then
    echo "📝 Creating credentials template..."
    cat > credentials << EOF
YOUR_PUSHOVER_USER_KEY
YOUR_PUSHOVER_APP_TOKEN
EOF
    echo "⚠️  IMPORTANT: Edit the 'credentials' file with your actual Pushover credentials!"
    echo "   Line 1: Your Pushover User Key"
    echo "   Line 2: Your Pushover App Token"
fi

# Make run script executable
if [ -f "run.sh" ]; then
    chmod +x run.sh
fi

# Create a simple requirements.txt for future reference
echo "📋 Creating requirements.txt..."
cat > requirements.txt << EOF
cloudscraper
beautifulsoup4
apprise
EOF

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Edit the 'credentials' file with your Pushover credentials"
echo "2. Run './run.sh <URL> <INSTANCE_NAME>' to start monitoring"
echo ""
echo "Example:"
echo "./run.sh 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments'"
echo ""
