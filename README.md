# ISH Institute Mobile Learning App

Official Flutter Android application for the **ISH Institute of Safety & Health** ([ishinstitutes.org](https://ishinstitutes.org)), providing workplace health and safety training for NEBOSH, IOSH, OSHA, First Aid, and Fire Safety.

Designed with a **Learning-First** methodology: **Learn -> Practice -> Test**. Games like **Hazard Hunt** are the delivery vehicle, while genuine safety comprehension and job interview readiness are the primary goals.

---

## Key Features

1. **Learning-First Architecture**:
   - 2-minute visual **Concept Cards** per topic before starting practice.
   - Comprehensive explanation after **every** MCQ answer (right or wrong), directly linked to related concept lessons.
   - Spaced Repetition **Review Queue** (1, 3, 7 days intervals) until concepts are mastered.
   - Mastery % tracking per topic/category, not just arbitrary points.
   - **Strictly NO calculators or calculation tools.**

2. **Bilingual Support (English + Urdu)**:
   - Dynamic in-app language switch in the top bar.
   - Urdu is fully **Right-to-Left (RTL)** and styled with **Noto Nastaliq Urdu** font metrics.
   - Bilingual content storage across all questions, explanations, concept cards, and interview answers.
   - Users can toggle languages anytime without losing state—even mid-quiz.

3. **Hazard Hunt Simulation Game**:
   - Interactive zoomable/pannable construction site scene (`InteractiveViewer`).
   - Pinpoints hidden site hazards with percentage coordinates `(x, y, radius)`.
   - On finding a hazard, maps the control measure directly to the **Hierarchy of Controls** (*Elimination, Substitution, Engineering, Administrative, PPE*).
   - 90-second countdown, 3 lives, and 2 hints per inspection.

4. **HSE Job Interview Preparation**:
   - Scenario-based questions categorized by role (HSE Officer, Safety Supervisor).
   - "Reveal Model Answer" mode with key interview talking points and bookmarking.

5. **Offline Support & Supabase Backend**:
   - High-performance local caching via **Hive** for 100% offline study capability.
   - **Supabase** backend for authentication (Email + Google), cloud database, and Row-Level Security (RLS).

---

## Folder Structure

Clean architecture organized by **feature**:

```
lib/
├── core/
│   ├── constants/           # Colors, dimensions, typography (Nastaliq & English)
│   ├── localization/        # AppLocale, AppStrings (EN & UR), LanguageProvider
│   ├── network/             # Supabase service & connection manager
│   ├── storage/             # Hive boxes, LocalCacheService & fallback seed provider
│   ├── theme/               # Material 3 light & dark theme, ThemeProvider
│   └── utils/               # Hierarchy of Controls, Spaced Repetition calculators
├── features/
│   ├── auth/                # Authentication with Supabase (Email + Google)
│   ├── onboarding/          # 3-slide visual onboarding with language selection
│   ├── home/                # Daily drill, streak counter, categories grid, feature cards
│   ├── categories/          # Learn / Practice / Test tabs with category mastery bar
│   ├── quiz/                # 10 MCQs, 20s timer, instant feedback, concept links, results
│   ├── hazard_hunt/         # InteractiveViewer canvas, hazards detection, controls modal
│   ├── flashcards/          # Swipeable study flashcards
│   ├── interview_prep/      # Job interview scenarios & model answers
│   ├── review_queue/        # Spaced repetition queue (1, 3, 7 days)
│   ├── leaderboard/         # Weekly top 20 rankings
│   ├── profile/             # Safety passport & statistics
│   └── contact/             # WhatsApp button & ishinstitutes.org link
├── shared/
│   └── widgets/             # BilingualText, LanguageSwitchButton, MasteryProgressBar, SafetyButton
└── main.dart
```

---

## Getting Started

### 1. Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.10.0)
- Android Studio / VS Code with Flutter extension
- Android device or emulator (Android 5.0+ / API 21+)

### 2. Configure Environment (`.env`)
Copy `.env.example` to `.env` in the root folder:
```bash
cp .env.example .env
```
Update your credentials:
```env
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
WHATSAPP_SUPPORT_NUMBER=923001234567
INSTITUTE_WEBSITE=https://ishinstitutes.org
```
*(Note: If left with defaults, the app runs offline using built-in local seed data.)*

### 3. Setup Supabase Database
1. Open your Supabase Project dashboard.
2. Go to the **SQL Editor**.
3. Open `supabase/schema.sql` from this repository.
4. Copy and paste the entire SQL file and click **Run**.
   - This creates all 11 tables (`profiles`, `categories`, `concept_cards`, `questions`, `interview_questions`, `hazard_levels`, `hazards`, `scores`, `bookmarks`, `level_progress`, `user_mastery`).
   - Enables Row-Level Security (RLS) on every table.
   - Seeds sample categories, concept cards, questions, hazards, and interview questions.

### 4. Install Dependencies & Run
```bash
flutter pub get
flutter run
```

---

## Android Configuration
- **Package Name**: `org.ishinstitutes.app`
- **Minimum SDK**: 21 (Android 5.0 Lollipop)
- **Target SDK**: 34 (Android 14)

---

## Institute Contact & Accreditation
- **Institute**: ISH Institute of Safety & Health
- **Official Website**: [ishinstitutes.org](https://ishinstitutes.org)
- **Courses**: NEBOSH IGC, IOSH Managing Safely, OSHA 30/10, First Aid at Work, Fire Safety
