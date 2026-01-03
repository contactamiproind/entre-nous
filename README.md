# ENEPL App

A Flutter application with Supabase backend for managing pathways, quizzes, and user progress.

## Quick Start

### Prerequisites
- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Supabase account and project

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd entre-nous
   ```

2. **Configure Environment Variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and add your Supabase credentials:
   ```
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **Install Dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## Documentation

- **[Production Setup Guide](PRODUCTION_SETUP.md)** - Complete production deployment guide
- **[Supabase Setup](SUPABASE_SETUP.md)** - Database and backend configuration
- **[Quick Start Guide](QUICK_START.md)** - Getting started quickly
- **[Android Build Guide](ANDROID_BUILD.md)** - Building for Android
- **[Emulator Setup](EMULATOR_SETUP.md)** - Setting up emulators

## Features

- User authentication (login/signup)
- Admin and user dashboards
- Department management
- Pathway assignments
- Quiz system with multiple question types
- Progress tracking
- Responsive design

## Security

- Environment variables for sensitive credentials
- No hardcoded API keys or secrets
- Supabase Row Level Security (RLS) enabled
- Secure authentication flows

## Project Structure

```
lib/
├── config/          # Configuration files
├── models/          # Data models
├── screens/         # UI screens
├── services/        # Business logic and API calls
├── theme/           # App theming
├── utils/           # Utility functions
└── widgets/         # Reusable widgets
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request

## License

[Add your license here]
