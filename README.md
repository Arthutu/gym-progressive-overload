# GymTracker - Progressive Overload Tracker

A native iOS app built with SwiftUI to track your gym workouts and monitor progressive overload. Features Live Activities for quick logging and voice recognition for hands-free set entry.

## Features

### Core Functionality
- **Workout Sessions**: Create and track workout sessions with date/time stamps
- **Exercise Tracking**: Log sets with weight (lbs) and reps for any exercise
- **Exercise Library**: Comprehensive predefined exercise list organized by muscle groups
- **Progress Visualization**: View your strength gains over time with interactive charts

### Advanced Features
- **Live Activities**: Quick access to workout logging via Dynamic Island and Lock Screen
- **Voice Recognition**: Hands-free set logging - just say "Bench press, 185 pounds, 8 reps"
- **Progress Charts**:
  - Weight progression over time
  - Volume tracking per workout
  - Personal records and statistics
- **SwiftData Persistence**: All data stored locally on device

### UI/UX
- **Minimal & Clean Design**: Apple-style interface with glassmorphism effects
- **Dark Mode Support**: Automatically adapts to system appearance
- **Smooth Animations**: Fluid transitions and interactions
- **Tab Navigation**: Easy switching between Workouts and Progress views

## Technical Details

### Requirements
- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's new data persistence framework
- **ActivityKit**: Live Activities and Dynamic Island integration
- **Speech Framework**: Voice recognition and transcription
- **Charts Framework**: Data visualization

### Project Structure
```
GymTracker/
├── GymTracker/
│   ├── Models/
│   │   ├── Models.swift              # SwiftData models
│   │   └── ExerciseData.swift        # Exercise database
│   ├── Views/
│   │   ├── WorkoutListView.swift     # Home screen
│   │   ├── ActiveWorkoutView.swift   # Active workout screen
│   │   ├── ExerciseSelectionView.swift
│   │   ├── ProgressView.swift        # Charts and statistics
│   │   └── VoiceInputView.swift      # Voice recognition UI
│   ├── Services/
│   │   └── VoiceRecognitionService.swift
│   ├── Utilities/
│   │   └── GlassModifier.swift       # UI styling
│   ├── GymTrackerApp.swift
│   └── ContentView.swift
└── GymTrackerWidget/
    ├── WorkoutLiveActivity.swift     # Live Activity implementation
    └── Info.plist
```

## Getting Started

### Installation
1. Open `GymTracker/GymTracker.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on your iOS device or simulator

### Permissions
The app requires the following permissions:
- **Microphone**: For voice input feature
- **Speech Recognition**: To transcribe voice commands

These will be requested on first use of the voice input feature.

## Usage

### Starting a Workout
1. Tap the **+** button on the Workouts tab
2. Select an exercise from the library
3. Enter sets manually or use voice input

### Manual Set Entry
1. Tap "Add Set" on the current exercise
2. Enter weight (lbs) and reps
3. Tap "Save Set"

### Voice Input
1. Tap the microphone button in Live Activity or active workout
2. Say your exercise, weight, and reps (e.g., "Bench press, 185 pounds, 8 reps")
3. Review parsed data and tap "Save Set"

### Live Activities
When a workout is active:
- **Lock Screen**: See current exercise and recent sets
- **Dynamic Island**: Quick stats and action buttons
- **Actions Available**:
  - Voice Input: Start voice recording
  - Manual: Add set manually
  - End: End current workout

### Viewing Progress
1. Switch to the Progress tab
2. Select an exercise from the list
3. View:
   - Max weight achieved
   - Total sets completed
   - Total volume (weight × reps)
   - Weight progression chart
   - Volume per workout chart

## Muscle Groups & Exercises

The app includes 70+ exercises across 13 muscle groups:
- Chest
- Back (Lats, Middle, Lower)
- Shoulders
- Biceps
- Triceps
- Forearms
- Quads
- Hamstrings
- Glutes
- Calves
- Abs

## Data Storage

All workout data is stored locally on your device using SwiftData. Data persists between app launches and is never sent to external servers.

## Future Enhancements

Potential features for future versions:
- iCloud sync across devices
- Workout templates and programs
- Rest timer between sets
- Export data to CSV/PDF
- Apple Watch companion app
- Social features and sharing
- Custom exercise creation
- Photo/video logging
- Body measurements tracking

## Development

### Building from Source
```bash
git clone <repository-url>
cd gym-progressive-overload
open GymTracker/GymTracker.xcodeproj
```

### Key Dependencies
All dependencies are system frameworks (no external packages):
- SwiftUI
- SwiftData
- ActivityKit
- WidgetKit
- Charts
- Speech
- AVFoundation

## License

MIT License

## Credits

Built with ❤️ using Swift and SwiftUI