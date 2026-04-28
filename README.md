# SPADE
**Synaptic Pipeline for Automated Decomposition of Electrophysiological data**

SPADE is an automated analysis pipeline for electrophysiology data. It provides a user-friendly frontend built in [Flutter](https://flutter.dev/) that seamlessly communicates with a robust [Python](https://www.python.org/) backend to process, visualize, and analyze Axon Binary Format (.abf) files with the use of the [pyABF package](https://pypi.org/project/pyabf) and other specialized packages.

## Features
* **Automated Python Environment:** Bundles and automatically extracts a portable Python distribution natively across OS platforms.
* **Raw Data Visualization:** Quickly view raw electrophysiology traces and export them to PNG or CSV.
* **Current Analysis:** Extract peak currents, integrated currents, and general current statistics within specific time windows.
* **I-V Relationship Analysis:** Analyze Current-Voltage (I-V) relationships, calculate reversal potentials, slope, intercept, and detect outliers.
* **Cross-Platform:** Designed to work natively using Flutter and portable Python distributions.

## Project Structure
* `lib/`: Flutter frontend codebase (Dart).
  * `main.dart`: Application entry point.
  * `services/`: Core logic, including `python_service.dart` for inter-process communication.
  * `model/`, `view/`, `viewModel/`: MVVM architecture implementation.
* `src/`: Python backend codebase.
  * `cli/`: Command-line interface for the Python pipeline.
  * `data_io/`: File parsing modules (e.g., `pyabf` integration).
  * `analysis/`: Core mathematical and electrophysiological analysis scripts.
  * `plotting/`: Visualization generators.

## Getting Started

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install)
* Embedded Python distribution bundled as `assets/python_dist.zip` (Required for the `PythonService` to extract upon first run).

### Running the App
1. Clone the repository.
2. Build the Python distribution bundled `build_zip.sh` or `build_zip.ps1`
2. Run `flutter pub get` to install Dart dependencies.
3. Start the application:
   ```bash
   flutter run