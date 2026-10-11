# Calculator App

## Overview

This project is a Flutter calculator application developed for the Mobile App Development course. It supports basic arithmetic, decimal calculations, and two evaluation modes: Left-to-Right and Standard precedence.

## Features

- **Basic arithmetic:** Addition, subtraction, multiplication, and division.
- **Decimal support:** Handles decimal values and prevents multiple decimal points in one operand.
- **Left-to-Right mode:** Evaluates operations in the order they are entered. For example, `2 + 3 × 4 = 20`.
- **Standard mode:** Follows conventional operator precedence and supports parentheses. For example, `2 + 3 × 4 = 14`.
- **Calculation history:** Keeps a record of previous calculations.
- **Advanced operations:** Includes percentage, square root, and sign toggle.
- **Backspace:** Deletes the most recently entered character.
- **Clear function:** Resets the current calculation.

## Technologies Used

- Flutter
- Dart
- Material Design

## Getting Started

### Prerequisites

Install Flutter and configure an emulator or connect a mobile device.

### Installation

1. Clone the repository:

   ```bash
   git clone <your-repository-url>
   ```

2. Navigate to the project directory:

   ```bash
   cd calculator_app
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

## Testing

Run the automated tests with:

```bash
flutter test
```

The tests cover arithmetic operations, decimal calculations, operator handling, clearing and resetting state, and evaluation using both calculation modes.

## Graduate Extension

The graduate extension adds conventional operator precedence and parentheses while preserving the original Left-to-Right mode. This allows users to switch between the two evaluation approaches.

## Project Structure

```text
calculator_app/
├── lib/
│   └── main.dart
├── test/
├── android/
├── ios/
├── pubspec.yaml
└── README.md
```

