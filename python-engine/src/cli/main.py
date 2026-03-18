import argparse
import os
from glob import glob

from src.plotting.view_raw_abf import plot_raw_data
from src.data_io.abf_parser import load_abf
from src.analysis.current_voltage_analysis import (
    extract_peak_current,
    extract_integrated_current,
    extract_current_stats,
)
from src.analysis.linearity_analysis import analyze_iv_relationship


def _parse_extra_kwargs(unknown_args):
    kwargs = {}
    for item in unknown_args:
        if "=" in item:
            key, value = item.split("=", 1)
            kwargs[key] = value
    return kwargs


def _build_time_window(start_time, end_time):
    if start_time is None or end_time is None:
        return None
    return float(start_time), float(end_time)


def _sweep_index(sweep_number):
    return int(sweep_number) if sweep_number is not None else None


def _handle_view_raw(args, filename, sweep_number, start_time, end_time):
    time, sweep_y, channel_labels = load_abf(args.abf_file, channel=args.channel)
    plot_raw_data(
        time,
        sweep_y,
        filename=filename,
        output_dir=args.output_dir,
        sweep_number=sweep_number,
        start_time=start_time,
        end_time=end_time,
        channel=args.channel,
        channel_labels=channel_labels,
    )


def _handle_extract_peak_current(args, sweep_number, time_window):
    time, sweep_y, _ = load_abf(args.abf_file, channel=args.channel)
    peak_results = extract_peak_current(
        sweep_y,
        time,
        time_window,
        sweep_number=_sweep_index(sweep_number),
    )
    for sweep_idx, data in peak_results.items():
        print(
            f"Sweep {sweep_idx} - Peak Current: {data['peak_current']}, Peak Time: {data['peak_time']}",
            flush=True,
        )


def _handle_extract_integrated_current(args, sweep_number, time_window):
    time, sweep_y, _ = load_abf(args.abf_file, channel=args.channel)
    integrated_results = extract_integrated_current(
        sweep_y,
        time,
        time_window,
        sweep_number=_sweep_index(sweep_number),
    )
    for sweep_idx, value in integrated_results.items():
        print(f"Sweep {sweep_idx} - Integrated Current: {value}", flush=True)


def _handle_extract_current_stats(args, sweep_number, time_window):
    time, sweep_y, _ = load_abf(args.abf_file, channel=args.channel)
    stats_results = extract_current_stats(
        sweep_y,
        time,
        time_window,
        sweep_number=_sweep_index(sweep_number),
    )
    for sweep_idx, stats in stats_results.items():
        print(
            f"Sweep {sweep_idx} - Peak Current: {stats['peak']}, "
            f"Integrated Current: {stats['integrated']}, "
            f"Mean Current: {stats['mean']}, Std Current: {stats['std']}",
            flush=True,
        )


def _collect_iv_file_data(abf_file_pattern):
    abf_files = sorted(glob(abf_file_pattern, recursive=True))
    print(f"Found {len(abf_files)} ABF files for I-V analysis.", flush=True)

    file_data = {}
    for abf_file in abf_files:
        clamp_time, clamp_sweep_y, clamp_channel_labels = load_abf(abf_file, channel=0)
        _, membrane_sweep_y, membrane_channel_labels = load_abf(abf_file, channel=1)
        _, stimuli_sweep_y, stimuli_channel_labels = load_abf(abf_file, channel=2)

        file_id = os.path.splitext(os.path.basename(str(abf_file)))[0]
        file_data[file_id] = {
            "clamp_sweepY": clamp_sweep_y,
            "membrane_sweepY": membrane_sweep_y,
            "stimuli_sweepY": stimuli_sweep_y,
            "clamp_time": clamp_time,
            "clamp_channel_labels": clamp_channel_labels,
            "membrane_channel_labels": membrane_channel_labels,
            "stimuli_channel_labels": stimuli_channel_labels,
        }

    return file_data


def _handle_analyze_iv(args, start_time, end_time):
    file_data = _collect_iv_file_data(args.abf_file)
    iv_results = analyze_iv_relationship(
        file_data,
        filename=os.path.basename(args.abf_file) if args.abf_file else None,
        time_window=_build_time_window(start_time, end_time),
        output_dir=args.output_dir,
    )
    print(
        f"Slope: {iv_results['slope']:.6f}, "
        f"Intercept: {iv_results['intercept']:.6f}, "
        f"R²: {iv_results['r_squared']:.4f}, "
        f"P-value: {iv_results['p_value']:.6f}",
        flush=True,
    )


def main():
    parser = argparse.ArgumentParser(
        description="Automated Python Pipeline for ABF Data Analysis"
    )
    
    parser.add_argument("--abf_file", type=str, help="Path to the ABF file")
    parser.add_argument("--output_dir", type=str, help="Output path")
    parser.add_argument("--channel", type=int, default=0, help="Channel index to analyze (default: 0)")

    # Function calls
    parser.add_argument("--view_raw", dest="view_raw", action="store_true", help="Plot raw data")
    parser.add_argument("--extract_peak_current", dest="extract_peak_current",  action="store_true", help="Extract peak current within a time window (format: start_time,end_time)")
    parser.add_argument("--extract_integrated_current", dest="extract_integrated_current",  action="store_true", help="Extract integrated current within a time window (format: start_time,end_time)")
    parser.add_argument("--extract_current_stats", dest="extract_current_stats",  action="store_true", help="Extract current statistics (mean, std) within a time window (format: start_time,end_time)")
    parser.add_argument("--analyze_iv", dest="analyze_iv", action="store_true", help="Analyze I-V relationship and detect outliers")

    args, unknown = parser.parse_known_args()
    kwargs = _parse_extra_kwargs(unknown)

    filename = os.path.basename(args.abf_file) if args.abf_file else None
    sweep_number = kwargs.get("sweep_number")
    start_time = kwargs.get("start_time")
    end_time = kwargs.get("end_time")
    time_window = _build_time_window(start_time, end_time)

    if args.view_raw:
        _handle_view_raw(args, filename, sweep_number, start_time, end_time)

    if args.extract_peak_current:
        _handle_extract_peak_current(args, sweep_number, time_window)
    
    if args.extract_integrated_current:
        _handle_extract_integrated_current(args, sweep_number, time_window)

    if args.extract_current_stats:
        _handle_extract_current_stats(args, sweep_number, time_window)
    
    if args.analyze_iv:
        _handle_analyze_iv(args, start_time, end_time)


if __name__ == "__main__":
    main()