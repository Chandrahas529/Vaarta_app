# Vaarta App

A modern, feature-rich chat application built with Flutter that enables real-time messaging, media sharing, and contact integration.

## Features

### Core Functionality
- **Real-time Messaging**: Instant messaging with WebSocket connectivity
- **User Authentication**: Secure JWT-based authentication with access and refresh tokens
- **Contact Integration**: Access and manage phone contacts
- **Media Sharing**: Send and receive images, videos, and audio messages
- **Push Notifications**: Background notifications for new messages

### Media & Content
- **Video Playback**: Built-in video player with controls
- **Image Viewer**: Full-screen image viewing with zoom capabilities
- **Emoji Support**: Rich emoji picker for expressive messaging

### User Experience
- **Themes**: Light and dark theme support
- **Profile Management**: User profiles with avatar upload
- **Status Updates**: User status and online presence
- **Settings**: Customizable app preferences
- **Camera Integration**: Take photos and videos directly in-app

### Technical Features
- **Cross-Platform**: Supports Android, iOS, Web, Windows, macOS, and Linux
- **State Management**: Provider pattern for efficient state handling
- **Local Storage**: Secure token storage and data persistence
- **Permission Handling**: Proper permission management for contacts, camera, etc.

## Screenshots

### Login & Authentication
<img src="screenshots/login_screen.png" alt="Login Screen" width="300"/>
<img src="screenshots/signup_screen.png" alt="Sign Up Screen" width="300"/>

### Chat Interface
<img src="screenshots/chat_list.png" alt="Chat List" width="300"/>
<img src="screenshots/chat_conversation.png" alt="Chat Conversation" width="300"/>

### Media Features
<img src="screenshots/image_sharing.png" alt="Image Sharing" width="300"/>
<img src="screenshots/video_player.png" alt="Video Player" width="300"/>

### Additional Features
<img src="screenshots/contacts_screen.png" alt="Contacts Screen" width="300"/>
<img src="screenshots/settings_screen.png" alt="Settings Screen" width="300"/>

## Getting Started

### Prerequisites

- Flutter SDK (^3.10.4)
- Dart SDK (^3.10.4)
- Android Studio / Xcode (for mobile development)
- Backend API server (for authentication and real-time messaging)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd vaarta_frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Backend Configuration**
   - Set up your backend API server with JWT authentication endpoints
   - Configure WebSocket server for real-time messaging
   - Update API endpoints in `lib/Config/Constants.dart`

4. **Configure Local Properties**
   - Update `android/local.properties` with your Android SDK path
   - Configure iOS settings in Xcode if building for iOS

### Running the App

#### Android
```bash
flutter run
```

#### iOS
```bash
flutter run --flavor development
```

#### Web
```bash
flutter run -d chrome
```

#### Other Platforms
```bash
flutter run -d <device-id>
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── Config/                   # Configuration files
│   ├── Constants.dart       # App constants
│   ├── LocalNotification.dart # Push notification setup
│   └── WebSocket.dart       # WebSocket connection
├── Data/                     # Data management
│   ├── AccessTokenGenerator.dart
│   └── TokenStorage.dart
├── Login_Logup/             # Authentication screens
├── MediaChat/               # Media message components
├── Modals/                  # Data models
├── PermissionHelper/        # Permission utilities
├── Providers/               # State management
├── Screens/                 # UI screens
├── Socket/                  # WebSocket handling
└── Utils/                   # Utility functions
```

## Dependencies

### Core Dependencies
- **provider**: State management
- **flutter_contacts**: Contact access
- **shared_preferences**: Local data storage for tokens
- **http**: API communication

### Media Dependencies
- **video_player**: Video playback
- **just_audio**: Audio playback
- **image_picker**: Image selection
- **photo_view**: Image viewing
- **chewie**: Video player controls

### UI Dependencies
- **cupertino_icons**: iOS-style icons
- **ionicons**: Icon library
- **emoji_picker_flutter**: Emoji picker

## Configuration

### API Configuration
1. Update your backend API base URL in `lib/Config/Constants.dart`
2. Configure JWT token endpoints for authentication
3. Set up WebSocket URL for real-time messaging
4. Configure token refresh logic in `lib/Data/AccessTokenGenerator.dart`

### Permissions
The app requires the following permissions:
- Contacts (READ_CONTACTS)
- Camera (CAMERA)
- Storage (READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE)
- Notifications

## Building for Production

### Android APK
```bash
flutter build apk --release
```

### iOS IPA
```bash
flutter build ios --release
```

### Web Build
```bash
flutter build web --release
```

## Testing

Run tests with:
```bash
flutter test
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Troubleshooting

### Common Issues

**Authentication Issues**
- Verify JWT token endpoints are correctly configured
- Check token expiration and refresh logic
- Ensure backend API is accessible

**WebSocket Connection Issues**
- Verify WebSocket server URL in configuration
- Check network connectivity
- Ensure backend WebSocket server is running

**Permission Denied**
- Grant required permissions in device settings
- Check permission handling in code

**Build Failures**
- Run `flutter clean` and `flutter pub get`
- Update Flutter SDK to latest stable version
- Check for deprecated dependencies

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, email [your-email@example.com] or create an issue in the repository.

## Acknowledgments

- Flutter team for the amazing framework
- All contributors and open-source libraries used
