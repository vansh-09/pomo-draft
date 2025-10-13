#!/bin/bash

# Start the Flask backend server for PomoDuo Quiz
echo "🚀 Starting PomoDuo Quiz Backend Server..."
echo "📍 Server will run on: http://localhost:5001"
echo "🔧 Make sure Flask is installed: pip install flask"
echo ""

cd backend
python3 app.py
