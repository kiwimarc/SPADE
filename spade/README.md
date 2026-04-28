# SPADE Flutter Frontend

This is the graphical user interface for **SPADE** (Synaptic Pipeline for Automated Decomposition for Electrophysiology data). Built with Flutter, it provides a cross-platform, user-friendly experience for analyzing electrophysiology data without needing to interact directly with the command line.

## Overview

The Flutter application serves as the orchestration layer for the Python analysis engine. It allows users to:
* Import and select `.abf` files.
* Configure analysis parameters (time windows, channels, reversal potentials) via an intuitive UI.
* Visualize raw data and generated plots directly within the app.
* Seamlessly trigger complex Python analytical processes in the background.

## Architecture

This project follows the **MVVM (Model-View-ViewModel)** architectural pattern to ensure clean separation of concerns:

* **View (`lib/view/`)**: The declarative UI components. Views listen to ViewModels for state changes and user interactions.
* **ViewModel (`lib/viewModel/`)**: The presentation logic layer. It holds the state, handles user input from the Views, and communicates with the Models/Services.
* **Model & Services (`lib/model/`, `lib/services/`)**: The data and business logic layer. 
  * The `BackendModel` manages the overarching state of the analysis pipeline.
  * The `PythonService` is a critical component that handles the extraction, initialization, and execution of the bundled Python environment.

## The Python Integration (`PythonService`)

Instead of relying on a system-wide Python installation or cloud APIs, SPADE runs a **fully local, embedded Python distribution**. 

1. **Bundling**: A portable Python environment is bundled as a zip file at `assets/python_dist.zip`.
2. **Extraction**: On the first run, `PythonService` securely extracts this distribution natively to the application's support directory.
3. **Execution**: The Flutter app communicates with the Python engine by spawning child processes using the native OS executables, capturing `stdout`/`stderr` for live UI updates.

## Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Ensure your environment is set up for Desktop/Mobile development depending on your target).
* The embedded Python distribution zip must be present at `assets/python_dist.zip`.

### Setup & Run
1. Get the Flutter dependencies:
   ```bash
   flutter pub get
  ```

2. Run the application in debug mode:
   ```bash
   flutter run
  ```
### Building for Release

**Windows:**

```bash
flutter build windows
```

**macOS:**

```bash
flutter build macos
```