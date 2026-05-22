# DebateCoach — Project Context for Claude Code
 
## What is this project?
DebateCoach is a Flutter mobile app that helps students sharpen critical thinking and argumentation skills by debating against an AI opponent. Users pick a topic, choose a stance (pro or con), then argue by typing or speaking. The AI generates real counter-arguments, scores the user's reasoning, and provides feedback. Progress is tracked over time with streaks, scores, and badges.
 
---
 
## SDGs
- SDG 4: Quality Education
- SDG 10: Reduced Inequalities
---
 
## Tech Stack
- **Framework**: Flutter (Dart)
- **Auth**: Firebase Authentication (email/password + Google SSO)
- **Database**: Cloud Firestore
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **File Storage**: Firebase Cloud Storage (bonus — profile photos)
- **Crash Reporting**: Firebase Crashlytics (bonus)
- **Primary AI API**: Groq API — model `llama-3.1-70b-versatile` (fast, generous free tier)
- **Fallback AI API**: Gemini API (official Dart SDK: `google_generative_ai`)
- **Topic Enrichment API**: Wikipedia REST API (free, no key needed)
- **Voice Input**: `speech_to_text` Flutter package (on-device, free)
- **Text-to-Speech**: `flutter_tts` Flutter package (on-device, free)
---
 
## API Links
- Groq API: https://console.groq.com/docs/openai
- Groq API key management: https://console.groq.com/keys
- Gemini API: https://ai.google.dev/gemini-api/docs
- Wikipedia REST API: https://en.wikipedia.org/api/rest_v1/
- speech_to_text package: https://pub.dev/packages/speech_to_text
- flutter_tts package: https://pub.dev/packages/flutter_tts
- google_generative_ai package: https://pub.dev/packages/google_generative_ai
---
 
## Groq API Call Pattern (Dart)
```dart
final response = await http.post(
  Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
  headers: {
    'Authorization': 'Bearer $groqApiKey',
    'Content-Type': 'application/json',
  },
  body: jsonEncode({
    'model': 'llama-3.1-70b-versatile',
    'messages': [
      {'role': 'system', 'content': 'You are a debate opponent. Generate a strong counter-argument.'},
      {'role': 'user', 'content': userArgument},
    ],
  }),
);
```
 
---
 
## Firebase Packages (pubspec.yaml)
```yaml
dependencies:
  firebase_core: latest
  firebase_auth: latest
  cloud_firestore: latest
  firebase_messaging: latest
  firebase_storage: latest       # bonus
  firebase_crashlytics: latest   # bonus
  google_generative_ai: latest   # Gemini fallback
  speech_to_text: latest
  flutter_tts: latest
  http: latest
```
 
---
 
## Features & PIC
 
| # | Feature | PIC | Notes |
|---|---------|-----|-------|
| 0 | User Authentication | All | Firebase Auth — mandatory, does NOT count toward feature quota |
| 1 | Debate Session | Person A | Core AI feature — chat with AI opponent |
| 2 | Topic Library | Person B | Community-built topic database |
| 3 | Progress Tracker | Person C | Scores, streaks, badges, history |
 
---
 
## Firestore Collections Schema
 
### `users/`
```
uid: String
name: String
email: String
photoURL: String
goal: String          // weekly practice goal
createdAt: DateTime
```
 
### `debateSessions/`
```
sessionId: String
userId: String
topicId: String
stance: String        // 'pro' or 'con'
messages: List<Map>   // subcollection or array
score: int
feedback: String
createdAt: DateTime
```
 
### `messages/` (subcollection under debateSessions)
```
messageId: String
sessionId: String
role: String          // 'user' or 'ai'
content: String
timestamp: DateTime
```
 
### `topics/`
```
topicId: String
title: String
category: String
difficulty: String    // 'easy', 'medium', 'hard'
submittedBy: String   // userId
sourceUrl: String     // optional Wikipedia link
createdAt: DateTime
```
 
### `progress/`
```
progressId: String
userId: String
scores: List<int>
streak: int
badges: List<String>
totalSessions: int
updatedAt: DateTime
```
 
---
 
## CRUD Map Per Feature
 
### Feature 1 — Debate Session (Person A)
- **C**: Start new session → create doc in `debateSessions/`
- **R**: Fetch messages in real time → read `messages/` subcollection
- **U**: Edit stance mid-session → update `stance` field in Firestore
- **D**: Delete session → remove session doc + messages subcollection
### Feature 2 — Topic Library (Person B)
- **C**: Add new topic → create doc in `topics/`
- **R**: Browse + search topics → query `topics/` with filters
- **U**: Edit topic → update title/category/difficulty in Firestore
- **D**: Delete topic → remove topic doc from Firestore
### Feature 3 — Progress Tracker (Person C)
- **C**: Save score → auto-create/update progress doc after session ends
- **R**: View history + stats → fetch `progress/` doc for current user
- **U**: Edit weekly goal → update `goal` field in `users/` doc
- **D**: Delete record → remove specific session score from scores array
---
 
## Navigation Bar Structure
4 tabs:
1. Home (session history / dashboard)
2. Debate (start / active debate session)
3. Topics (topic library)
4. Progress (tracker, stats, badges)
---
 
## Class Structure
 
### Core Models
- `User` — uid, name, email, photoURL, goal, createdAt
- `DebateSession` — sessionId, userId, topicId, stance, messages, score, feedback, createdAt
- `Message` — messageId, sessionId, role, content, timestamp
- `Topic` — topicId, title, category, difficulty, submittedBy, sourceUrl, createdAt
- `ProgressRecord` — progressId, userId, scores, streak, badges, totalSessions, updatedAt
- `Badge` — badgeId, name, description
### Service Classes
- `AIService` — generateCounterArgument(), scoreDebate(), getFeedback(), fetchTopicContext()
- `NotificationService` — sendPushNotification(), scheduleReminder(), cancelReminder()
- `AuthService` — signUpWithEmail(), loginWithGoogle(), logout(), resetPassword()
---
 
## 4-Week Task Plan
 
### Week 1 — Foundation (setup + Create)
**Person A (Debate Session)**
- Init Flutter project, connect Firebase
- Create `debateSessions/` Firestore collection with schema
- Build "Start new debate session" screen — pick topic + stance, save to Firestore (C)
**Person B (Topic Library)**
- Create `topics/` Firestore collection with schema
- Build "Add new topic" form screen — save to Firestore (C)
- Seed Firestore with 5–10 sample topics for testing
**Person C (Progress Tracker)**
- Create `progress/` Firestore collection with schema
- Setup Firebase Auth — register + login screens
- Build "Save score" logic — auto-create progress doc after session ends (C)
**All members**
- GitHub repo created, branch strategy agreed (main / dev / feature branches)
- Navigation bar skeleton with 4 tabs wired up
- Firebase connected on all machines
---
 
### Week 2 — Core CRUD (Read + Update + AI integration)
**Person A (Debate Session)**
- Build debate chat screen — fetch + display messages from Firestore in real time (R)
- Integrate Groq API — send user argument, receive AI counter-argument, save reply (S)
- Build "Edit stance" — allow user to switch pro/con mid-session, update Firestore (U)
**Person B (Topic Library)**
- Build topic browse screen — fetch all topics, display with category filter (R)
- Build topic search — query Firestore by title keyword (R)
- Build "Edit topic" screen — pre-filled form, update Firestore (U)
**Person C (Progress Tracker)**
- Build history screen — fetch all past sessions + scores from Firestore (R)
- Build stats display — total sessions, average score, streak calculation (R)
- Build "Set weekly goal" screen — update progress doc in Firestore (U)
---
 
### Week 3 — Delete + Push Notifications + Polish
**Person A (Debate Session)**
- Build "Delete session" — swipe-to-delete, remove doc + messages from Firestore (D)
- Add AI debate scoring — call Groq after session ends, save score to Firestore
- Add voice input — integrate `speech_to_text` package, mic button on chat screen
**Person B (Topic Library)**
- Build "Delete topic" — confirmation dialog, remove from Firestore (D)
- Integrate Wikipedia API — fetch background context on topic detail screen
- Setup push notification — notify all users when new topic is added
**Person C (Progress Tracker)**
- Build "Delete record" — remove specific session from history, delete from Firestore (D)
- Setup push notification — weekly reminder if user hasn't practiced (FCM)
- Build badge system — auto-award badge on streak/score milestone, update Firestore
**Bonus (if ahead of schedule)**
- Person A: add `firebase_crashlytics`
- Person B: add Cloud Storage for profile photos
- Person C: add score chart using `fl_chart` package
---
 
### Week 4 — Integration + Testing + Demo Prep
**Person A (Debate Session)**
- End-to-end test: start session → argue → AI replies → score saved → shows in progress
- Fix bugs, handle loading + error states on all screens
- Rehearse live code-modification demo for debate session feature
**Person B (Topic Library)**
- End-to-end test: add topic → browse → search → edit → delete → verify in Firestore console
- Handle Wikipedia API timeout + no-internet edge cases
- Rehearse live code-modification demo for topic library feature
**Person C (Progress Tracker)**
- End-to-end test: complete debate → score in history → streak updates → badge awarded
- Test push notification on real device
- Rehearse live code-modification demo for progress tracker feature
**All members — final checklist**
- Final GitHub push with clean commit history
- README written with setup instructions
- Firestore security rules reviewed
- APK build tested on real device
- Every member can explain and debug every line of their own feature
---
 
## Key Rules for This Project
1. Every feature must have full CRUD — do not skip Delete
2. Every feature must have end-to-end cloud connection (Flutter ↔ Firestore)
3. Weekly commits are mandatory — commit something every week even if small
4. Auth (Firebase Auth) is mandatory but does NOT count as a feature
5. External API is mandatory — Groq API satisfies this requirement
6. Push notifications are mandatory — wire FCM in Week 3
7. Navigation bar is mandatory — build skeleton in Week 1
8. AI tools for code generation are allowed but each member must be able to debug their own code live
---
 
## Device & Environment
- Development OS: Windows 11
- Test device: Android (iQOO Z7 5G, Android 15)
- Build workaround if needed: `flutter build apk --debug` + `adb install`
---
 
## References
- Flutter docs: https://docs.flutter.dev
- Firebase Flutter setup: https://firebase.google.com/docs/flutter/setup
- Groq API docs: https://console.groq.com/docs/openai
- Gemini Flutter quickstart: https://ai.google.dev/gemini-api/docs/get-started/tutorial?lang=dart
- SDG 4: https://sdgs.un.org/goals/goal4
- SDG 10: https://sdgs.un.org/goals/goal10