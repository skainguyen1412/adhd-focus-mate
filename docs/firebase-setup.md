# Firebase Setup for ADHD Timer AI

## Prerequisites
1. A Firebase project
2. Vertex AI API enabled in Google Cloud Console

## Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use an existing one
3. Note your Project ID

### 2. Enable Vertex AI API
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Search for "Vertex AI API" and enable it
4. Also enable "Generative Language API" for Gemini access

### 3. Add macOS App to Firebase
1. In Firebase Console, click "Add app" → Apple
2. Enter bundle ID: `dev.tuist.ADHDTimerAI`
3. Download `GoogleService-Info.plist`
4. Place it in: `ADHDTimerAI/ADHDTimerAI/Resources/GoogleService-Info.plist`

### 4. Update Info.plist (if needed)
Add Firebase configuration keys if required for your setup.

### 5. Rebuild the App
```bash
cd ADHDTimerAI
tuist generate
```

## Alternative: Use Gemini API Key (Simpler)
If you prefer to use the Gemini Developer API instead of Vertex AI:

1. Get an API key from [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Switch provider to "OpenAI Compatible" in Settings
3. Set endpoint: `https://generativelanguage.googleapis.com/v1beta/openai`
4. Enter your Gemini API key
5. Use model: `gemini-2.0-flash`

This uses the OpenAI-compatible endpoint that Gemini provides, which works without Firebase setup.
