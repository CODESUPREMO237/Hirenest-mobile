# HireNest Mobile App

HireNest is Cameroon's premier digital recruitment and freelance marketplace ecosystem. This application is built to seamlessly connect job seekers, freelancers, and employers through a modern, fast, and accessible mobile interface.

## 🚀 Features

### For Job Seekers & Freelancers
- **Smart Job Search**: Filter jobs dynamically by role, location, salary, and job type using a modern bottom sheet filter system.
- **Freelance Marketplace**: Offer services directly to employers or individuals. Manage active gigs and payouts.
- **Real-Time Chat**: Connect directly with employers through built-in instant messaging.
- **One-Tap Applications**: Apply to jobs quickly with a securely saved profile.

### For Employers
- **Company Dashboard**: Manage company profiles, including logos, banners, and descriptions.
- **Post & Manage Jobs**: Easily list new roles, set dynamic requirements, and review applicants.
- **Admin Management**: Assign multi-user access to company accounts to help manage large applicant pools.

### Technical Features
- **Dynamic Theming**: Complete Material 3 Design implementation with customized color swatches, smooth animations, and custom UI elements.
- **State Management**: Robust architecture powered by **Riverpod**.
- **Routing**: Deep linking and advanced navigation managed via **GoRouter**.
- **Network Architecture**: Secure API interactions handled via **Dio** with built-in token management and error handling overlays.
- **Media**: Integrated image picking and cropping for avatars, banners, and logos.

## 🛠 Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Navigation**: GoRouter (`go_router`)
- **Networking**: Dio (`dio`)
- **Local Storage**: Flutter Secure Storage (`flutter_secure_storage`), Shared Preferences
- **Icons**: Phosphor Icons (`phosphor_flutter`), Lucide Icons (`lucide_icons`)

## 📦 Getting Started

### Prerequisites
- Flutter SDK (`>=3.0.0`)
- Android Studio / Xcode
- A running instance of the HireNest Node.js Backend

### Installation

1. **Clone the repository:**
   ```bash
   git clone git@github.com:CODESUPREMO237/Hirenest-mobile.git
   cd Hirenest-mobile
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Environment Variables:**
   Ensure that the API base URL in `lib/core/network/api_client.dart` or your environment variables is pointing to the correct backend address.

4. **Run the App:**
   ```bash
   flutter run
   ```

## 🎨 UI/UX Design System

The application strictly adheres to the Phase 2 HireNest Design System:
- **Primary Color**: Deep Blue (`#0B4D9E`)
- **Secondary Color**: Vivid Orange (`#F26522`)
- **Typography**: Poppins (Headings) / Open Sans (Body)
- **Border Radii**: Smooth `16px` for cards, `32px` for pills.

## 🤝 Contributing
1. Create a new feature branch (`git checkout -b feature/amazing-feature`)
2. Commit your changes using conventional commits (`git commit -m 'feat: added amazing feature'`)
3. Push to the branch (`git push origin feature/amazing-feature`)
4. Open a Pull Request

---
*Built with ❤️ for Cameroon's digital future.*
