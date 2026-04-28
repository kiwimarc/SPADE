# Python Engine CLI Quick Run Guide

The SPADE. Python engine is a specialized tool for automated electrophysiology analysis. It handles data parsing, signal processing for current-voltage relationships, and high-quality plot generation.

The primary entry point for the engine is `src/cli/main.py`.

## Environment Setup

Before running the commands, ensure you are in the root directory (where the `src` folder is located) and that your `PYTHONPATH` is configured so the script can resolve internal modules.

PowerShell:

```powershell 
$env:PYTHONPATH = "src"
python src/cli/main.py <FLAGS> --abf_file "path/to/data.abf" --output_dir "./output"
``` 

Bash/WSL:

```bash 
export PYTHONPATH=src
python3 src/cli/main.py <FLAGS> --abf_file "path/to/data.abf" --output_dir "./output"
``` 

## CLI Core Functionality

The engine uses two types of arguments: Global Flags (starting with `--`) for the main operation and Parameter Arguments (`key=value`) for fine-tuning the analysis.

### View Raw Traces

Visualizes the raw recordings from an ABF file. It supports zooming into specific time windows and selecting individual sweeps.

```bash 
python src/cli/main.py --view_raw --abf_file "data/file.abf" --output_dir "./output" channel=0 sweep_number=0 start_time=0.01 end_time=0.05
``` 

Key Parameters:

* `channel`: The channel index to plot (default is 0).
* `sweep_number`: Plot a single specific sweep index.
* `selected_sweeps`: A comma-separated list (e.g., 0,2,4) to plot multiple specific sweeps.
* `start_time` / `end_time`: Zoom the x-axis to these bounds (in seconds).
* `export_format`: Plot format (png, pdf, svg, etc.).

### Current Extraction Commands

These commands analyze signal amplitude and area within a specified time window. Results are printed directly to the terminal.

| Feature              | Flag                         | Description                                                      |
|---------------------|------------------------------|------------------------------------------------------------------|
| Peak Current        | --extract_peak_current       | Finds the maximum absolute current and its timestamp.            |
| Integrated Current  | --extract_integrated_current | Calculates the total current area (charge) over time.            |
| Current Stats       | --extract_current_stats      | Provides peak, integrated, mean, and standard deviation.         |

### I-V Relationship Analysis

Analyzes the linearity of the current-voltage relationship across multiple files. It estimates leak current, fits a linear regression, and calculates synaptic conductances (Gsyn​, Ge​, Gi​) and E/I ratios.

```bash 
python src/cli/main.py --analyze_iv --abf_file "data/*.abf" --output_dir "./output" start_time=0.01 end_time=0.05 e_rev=0 i_rev=-70
``` 

Key Parameters:

* `e_rev`: Excitatory reversal potential (default: 0 mV).
* `i_rev`: Inhibitory reversal potential (default: -60 mV).
* `clamp_channel`: Data channel for current (default: 0).
* `membrane_channel`: Data channel for voltage (default: 1).
* `stimuli_channel`: Data channel for stimulus timing (default: 2).

### CSV Data Export

By default, the engine generates visual plots (.png). Add the `--export_csv` flag to any command to save the raw or processed data as a .csv file instead.

```bash 
python src/cli/main.py --view_raw --abf_file "data/file.abf" --output_dir "./output" --export_csv
```

## Argument Reference Table

All `key=value` parameters must be provided without spaces around the `=` sign.


| Parameter            | Type   | Default | Usage                                      |
|---------------------|--------|---------|--------------------------------------------|
| channel             | Int    | 0       | Target data channel.                       |
| start_time          | Float  | None    | Analysis window start (sec).               |
| end_time            | Float  | None    | Analysis window end (sec).                 |
| sweep_number        | Int    | None    | Single sweep to analyze.                   |
| export_format       | String | png     | Plot file extension.                       |
| e_rev / i_rev       | Int    | 0/-60   | Reversal potentials for I-V.               |


## Troubleshooting

* File Paths: If using glob patterns (e.g., *.abf) on Windows, ensure you wrap the path in double quotes to prevent the shell from expanding the wildcard prematurely.
* Stimulus Detection: The I-V analysis expects a stimulus pulse to be present on the stimuli_channel to identify baseline/leak periods.