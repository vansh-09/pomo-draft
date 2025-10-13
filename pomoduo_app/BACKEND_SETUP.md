# Backend Setup for PomoDuo Quiz

## Quick Start

To start the backend server:

```bash
cd backend
python3 app.py
```

Or use the provided script:
```bash
./start_backend.sh
```

## Requirements

- Python 3.x
- Flask: `pip install flask`

## Features

- **Fallback System**: If the backend is unavailable, the app automatically uses local questions
- **Multiple Topics**: Supports C Programming, COA, and DSGT
- **Offline Mode**: Works without internet connection using local question bank

## Troubleshooting

### "No questions available" Issue

This has been fixed with the following improvements:

1. **Local Fallback**: The app now includes a comprehensive local question bank
2. **Better Error Handling**: Improved timeout and connection error handling
3. **User Feedback**: Clear indication when using offline mode
4. **Retry Mechanism**: Users can retry loading questions

### Backend Not Starting

1. Check if Python 3 is installed: `python3 --version`
2. Install Flask: `pip install flask`
3. Check if port 5001 is available
4. Try a different port by modifying `app.py`

### Network Issues

The app now works in offline mode with local questions, so network issues won't prevent quiz functionality.
