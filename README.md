# Flutter TODO App

A full-featured, real-time TODO Flutter application with task sharing capabilities and live updates.

## Features

- Create, update, and delete tasks
- Categorize tasks (Work, Personal, Urgent, etc.)
- Mark tasks as completed
- Share tasks with other users
- Real-time updates across devices
- Category-based filtering
- Modern and responsive UI
- Slide actions for quick task management

## Technical Stack

- Flutter
- Firebase Firestore for real-time data sync
- Provider for state management
- MVVM Architecture

## Getting Started

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Set up Firebase:
   - Create a new Firebase project
   - Add your Firebase configuration files
   - Enable Firestore database
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── models/
│   └── task.dart
├── services/
│   └── firebase_service.dart
├── viewmodels/
│   └── task_view_model.dart
├── views/
│   ├── screens/
│   │   └── home_screen.dart
│   └── widgets/
│       ├── task_item.dart
│       └── add_task_dialog.dart
└── main.dart
```

## Dependencies

- provider: ^6.1.2
- firebase_core: ^2.27.1
- firebase_auth: ^4.17.9
- cloud_firestore: ^4.15.9
- flutter_slidable: ^3.0.1
- share_plus: ^7.2.2
- uuid: ^4.3.3
- google_fonts: ^6.2.1
- shimmer: ^3.0.0
- intl: ^0.19.0

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
