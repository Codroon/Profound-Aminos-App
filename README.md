# WooCommerce Management App

A comprehensive Flutter application for managing WooCommerce stores, WordPress content, and customer support through Gorgias integration.

## Features

### 🛍️ WooCommerce Management
- **Analytics Dashboard**: Real-time sales data, order statistics, and revenue tracking
- **Order Management**: View all orders with detailed information and status tracking
- **Product Management**: Create, edit, and manage products with image upload support
- **Sales Reports**: Comprehensive sales analytics and reporting

### 📝 WordPress Integration
- **Post Management**: Create, edit, and publish WordPress posts
- **Media Upload**: Upload images directly to WordPress media library
- **Content Management**: Full CRUD operations for WordPress content

### 🎫 Customer Support (Gorgias)
- **Ticket Management**: View and manage customer support tickets
- **Message Handling**: Send and receive messages through Gorgias API
- **Support Analytics**: Track support metrics and performance

### 👤 User Profile
- **Account Management**: User profile and settings
- **Business Features**: Business-related configurations
- **App Settings**: Application preferences and configurations

## Technical Stack

- **Framework**: Flutter
- **State Management**: BLoC Pattern
- **HTTP Client**: Dio
- **Local Storage**: Flutter Secure Storage
- **UI Components**: Custom widgets with consistent theming
- **Architecture**: Clean Architecture with Repository Pattern

## Project Structure

```
lib/
├── core/
│   ├── constants/
│   ├── di/
│   ├── error/
│   ├── network/
│   ├── routes/
│   ├── services/
│   ├── storage/
│   ├── theme/
│   └── utils/
├── features/
│   ├── analytics/
│   ├── auth/
│   ├── gorgias/
│   ├── home/
│   ├── notifications/
│   ├── products/
│   ├── profile/
│   └── word_press/
└── widgets/
```

## Security Note

For security reasons, the following files containing sensitive API configurations and service implementations have been excluded from this public repository:

- `lib/core/services/wordpress_service.dart`
- `lib/core/services/gorgias_service.dart`
- `lib/features/word_press/presentation/pages/`
- `lib/features/products/presentation/pages/create_product_page.dart`
- `lib/features/products/presentation/pages/edit_product_page.dart`

These files contain API endpoints, authentication methods, and business logic that should remain private.

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure your API credentials (not included in this repository)
4. Run `flutter run` to start the application

## Development

This project follows Flutter best practices and clean architecture principles. Each feature is modularized with its own BLoC for state management and repository for data handling.

## Contributing

Please ensure that any contributions maintain the existing code structure and do not include sensitive configuration files.

## License

This project is proprietary and confidential.
