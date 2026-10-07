# Cloud Music Player — v0.2

A clean-room Android music player with a unified Local + Google Drive library and an isolated YouTube Music personal-upload connector boundary.

## What is implemented
- Kotlin + Jetpack Compose
- AndroidX Media3 1.11.1 playback engine and MediaSession
- In-app play/pause controls (tracks are no longer handed off to another player)
- Local MediaStore scanner
- Google Drive / cloud storage folder selection through Android Storage Access Framework
- Recursive Drive folder scanning
- Persistent selected Drive folder
- Unified Local + Drive library
- Search across title, artist and album
- Source labels
- Metadata attached to Media3 playback items
- Android background media service
- YouTube Music Uploads connector interface kept isolated from the player

## Telegram (online music, TDLib)
Uses TDLib (prebuilt AAR from JitPack) as a real Telegram client. Get an API ID/hash at my.telegram.org, tap **Telegram**, enter them, log in with your phone number, then pick a channel or group. All audio in it (full history) appears in the library; tapping a song downloads it via TDLib and plays it in-app. Files up to 2 GB work.

## Google Drive
The app uses ACTION_OPEN_DOCUMENT_TREE / Storage Access Framework. The user chooses the Drive folder and grants the app read access. This avoids storing a Google password in the app and works with cloud document providers exposed to Android.

## YouTube Music Uploads
YouTube Music personal uploads are intentionally not implemented through an unofficial scraper or a fake public API. Google supports personal uploads inside YouTube Music but does not provide a public third-party API that exposes the private uploaded audio files to arbitrary music players.

The project contains `YouTubeMusicUploadsRepository` so a legitimate supported connector/data source can be added without changing the library or player architecture.

## Build
Open `CloudMusicPlayer` in Android Studio and let Gradle sync. The project targets Android API 35 and uses Media3 1.11.1.

The source was updated against Google's current Media3 documentation, but this environment does not contain an Android SDK/Gradle installation, so the APK has not been compiled here.
