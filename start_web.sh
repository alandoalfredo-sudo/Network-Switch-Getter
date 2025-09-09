#!/bin/bash

# Network Switch Getter - Web Interface Startup Script

echo "🌐 Network Switch Getter - Web Interface"
echo "========================================"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3 first."
    exit 1
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null; then
    echo "❌ pip3 is not installed. Please install pip3 first."
    exit 1
fi

# Install dependencies
echo "📦 Installing Python dependencies..."
pip3 install -r requirements.txt

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies. Please check the requirements.txt file."
    exit 1
fi

echo "✅ Dependencies installed successfully!"

# Start the web server
echo "🚀 Starting web server..."
echo "🔗 Open in browser: http://localhost:8000"
echo "📊 API Documentation: http://localhost:8000/api/health"
echo "========================================"

python3 app.py
