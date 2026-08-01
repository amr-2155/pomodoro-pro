# 🍅 Pomodoro Pro

A beautiful and feature-rich Pomodoro timer app built with **Flutter**.

Works on **Web (PWA)**, **Android (APK)**, and iOS — all from a single codebase.

## ✨ Features

- ⏱️ **Pomodoro Timer** — focus / short break / long break with full control
- 📁 **Projects** — organize sessions and track progress per project
- ✅ **Tasks** — to-do list with estimated & completed pomodoros
- 📊 **Statistics** — daily, weekly & monthly charts, start-of-week setting
- 🌙 **Dark Mode** — manual toggle + follows system
- 🌧️ **Ambient Sounds** — rain, forest, ocean, cafe, white noise (web)
- 🔔 **Notifications** — web notifications when a session ends
- 💾 **Backup & Restore** — export/import your data as JSON
- 📤 **CSV Export** — sessions & tasks export via share sheet
- 📲 **PWA** — installable on any device, works offline (web)
- 🎯 **Daily Goal** & **Long Break Interval** customization

## 🚀 Live App

Try it online: **https://amr-2155.github.io/pomodoro-pro/**

## 📲 Download Android APK

Grab the latest APK from the **Releases** page:
**https://github.com/amr-2155/pomodoro-pro/releases**

> On your phone, enable "Install from unknown sources" to sideload the APK.

## 🛠️ Build from source

```bash
# Web
flutter build web
flutter run -d chrome

# Android
flutter build apk --release
```

## 🏗️ Tech Stack

- **Framework:** Flutter 3.x / Dart
- **Storage:** Hive (fast, local, no server needed)
- **State:** Provider
- **Web:** PWA + Service Worker, Web Audio API for ambient sounds

## 📄 License

MIT
