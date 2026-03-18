# Python Engine CLI Quick Run Guide

This project entrypoint is `src/cli/main.py`.

## Run format (from `python-engine/`)

PowerShell:

```powershell
$env:PYTHONPATH = "src"
python -m cli.main <FLAGS> --abf_file "..\data\2026_01_30_0000.abf" --output_dir ".\output"
```

Bash/WSL:

```bash
PYTHONPATH=src python -m cli.main <FLAGS> --abf_file "../data/2026_01_30_0000.abf" --output_dir "./output"
```

## Elements in `main.py`

### 1) View raw trace

```powershell
$env:PYTHONPATH="src"
python -m cli.main --view_raw --abf_file "..\data\2026_01_30_0000.abf" --output_dir ".\output" --channel 0 sweep_number=0 start_time=0.01 end_time=0.05
```

### 2) Extract peak current

```powershell
$env:PYTHONPATH="src"
python -m cli.main --extract_peak_current --abf_file "..\data\2026_01_30_0000.abf" start_time=0.01 end_time=0.05 sweep_number=0
```

### 3) Extract integrated current

```powershell
$env:PYTHONPATH="src"
python -m cli.main --extract_integrated_current --abf_file "..\data\2026_01_30_0000.abf" start_time=0.01 end_time=0.05 sweep_number=0
```

### 4) Extract current stats

```powershell
$env:PYTHONPATH="src"
python -m cli.main --extract_current_stats --abf_file "..\data\2026_01_30_0000.abf" start_time=0.01 end_time=0.05 sweep_number=0
```

### 5) Analyze I-V across many files

```powershell
$env:PYTHONPATH="src"
python -m cli.main --analyze_iv --abf_file "..\data\*.abf" --output_dir ".\output" start_time=0.01 end_time=0.05
```

## Notes

- `start_time` and `end_time` are passed as `key=value` extra arguments.
- `--analyze_iv` expects a glob path (example: `..\data\*.abf`).
- `--channel` is used for single-file operations (`--view_raw`, current extraction commands).
