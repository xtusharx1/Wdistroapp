# Wdistro

## Overview

Wdistro is a mobile application developed for Woodland Distributors, tailored to streamline wholesale distributor workflows and inventory operations. The platform enables buyers and business partners to seamlessly browse catalog items, review product specifications, inspect permits, and manage orders from a centralized interface.

Designed with operational efficiency in mind, the app features real-time inventory barcode scanning, persistent draft order management, digital permit verification, and streamlined checkout pipelines. By digitizing key B2B touchpoints, Wdistro reduces administrative overhead and minimizes order fulfillment friction.

Built for scalability and reliability, Wdistro bridges field distributors with core distribution management systems, ensuring transparent order status tracking, rapid reordering capabilities, and consistent operational compliance across all distribution channels.

## Tech Stack

- **Framework**: Flutter (Dart SDK ^3.8.1)
- **State Management & Services**: Service-oriented architecture with reactive application state (`AppState`, `ApiClient`)
- **UI & Styling**: Material Design 3, custom typography via `google_fonts`
- **Core Dependencies**:
  - `http`: REST API communication
  - `mobile_scanner`: Barcode and QR code scanning capabilities
  - `shared_preferences`: Persistent local key-value storage
  - `file_picker`: Document and file selection
  - `url_launcher`: External URL handling

## Prerequisites

Before setting up and running Wdistro, ensure your development environment has the following installed:

- **Flutter SDK**: v3.27.0 or higher
- **Dart SDK**: ^3.8.1
- **Android Studio** / **VS Code**: With Flutter and Dart plugins installed
- **JDK**: Version 17 or higher (for Android builds)
- **Xcode & CocoaPods**: Latest versions (required for iOS builds on macOS)

## How to Run the Project

Follow these steps to set up and run the application locally:

### 1. Clone the repository

```bash
git clone https://github.com/xtusharx1/Wdistroapp.git
cd Wdistroapp
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run the app

Connect a mobile device or start an emulator, then execute:

```bash
flutter run
```

## Build Commands

Execute the following commands from the root directory to generate production builds:

### Android APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

## Folder Structure

Below is a brief overview of the project's source structure (`lib/`):

```text
lib/
├── core/
│   ├── models/        # Data models (Product, Order, DraftOrder, CartState, ShopPermit)
│   ├── services/      # Service layer for API, Auth, Orders, Products, and Permits
│   ├── state/         # Centralized application state management (AppState)
│   └── theme/         # Application styling, color tokens, and Material themes
├── screens/           # Application screens (Auth, Home, Products, Cart, Orders, Profile)
├── widgets/           # Shared and reusable UI components
└── main.dart          # Application entry point
```

## License

This project is licensed under the MIT License.
