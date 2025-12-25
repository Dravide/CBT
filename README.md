# CBT App (Computer Based Test)

A Flutter-based Computer Based Test application designed for students and schools to manage exams, schedules, and announcements effectively.

## Features

*   **Authentication**: Secure login for students using NIS/NISN.
*   **Dashboard**: Overview of upcoming exams and quick access to features.
*   **Exam Interface**: User-friendly exam taker with timer and question navigation.
*   **Schedule (Jadwal)**: Weekly class schedule viewer.
*   **Announcements (Pengumuman)**: Stay updated with school news.
*   **Profile**: Student profile with stats and social-media style achievements.
*   **Social Feed**: A space for student interaction (Demo).

## Technology Stack

*   **Framework**: Flutter (Dart)
*   **State Management**: `setState` (Simple & Effective for current scale)
*   **Networking**: `http` package for API integration.
*   **UI/UX**: Custom components, Google Fonts (`Plus Jakarta Sans`), and Skeleton Loading for smooth UX.
*   **Local Storage**: `shared_preferences` for session management.

## Getting Started

### Prerequisites

*   Flutter SDK (v3.0.0 or higher)
*   Dart SDK
*   Android Studio / VS Code

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/yourusername/cbt_app.git
    cd cbt_app
    ```

2.  Install dependencies:
    ```bash
    flutter pub get
    ```

3.  Run the application:
    ```bash
    flutter run
    ```

## Project Structure

*   `lib/pages`: Contains all screen UI code (Home, Profile, Exam, etc.).
*   `lib/services`: API service layers.
*   `lib/models`: Data models for JSON serialization.
*   `lib/widgets`: Reusable UI components (Custom Headers, Skeleton Loading, etc.).

## Contact

Developed by [Your Name/Team].
