import numpy as np

from src.analysis.iv_regression import (
    average_regression,
    estimate_leak_current,
    get_window_indices,
    run_regression_over_time,
)
from src.plotting.iv_analysis_plots import (
    plot_iv_relationship,
    plot_predicted_current_over_time,
    plot_slopes_over_time,
    plot_Gsyn_Ge_Gi_over_time,
    plot_ei_ratio_over_time,
    plot_e_fraction_over_time,
)
from src.utils.time import seconds_to_milliseconds

def analyze_iv_relationship(file_data, filename, time_window, output_dir):
    """
    Analyzes I-V relationship: fits linear regression, computes R², detects outliers.
    
    Args:
        file_data: dict with file_id as keys, each containing:
            - clamp_sweepY: 2D array of currents (sweeps x timepoints)
            - clamp_time: time array for current channel
            - membrane_sweepY: 2D array of voltages (sweeps x timepoints)
            - clamp_channel_labels: labels for clamp channel
            - membrane_channel_labels: labels for membrane channel
        filename: identifier for the file (for plotting)
        time_window: (start_ms, end_ms) tuple for time window
        output_dir: directory to save plot
    
    Returns:
        dict: Contains slope, intercept, r_squared, p_value, outlier_indices
    """
    
    currents = []
    voltages = []

    # Get channel labels from first file
    first_data = next(iter(file_data.values()))
    clamp_channel_labels = first_data['clamp_channel_labels']
    membrane_channel_labels = first_data['membrane_channel_labels']
    stimuli_sweepY = first_data['stimuli_sweepY']

    # Use the first sweep for stimulus timing detection.
    stimuli_time = find_stim_pulse(stimuli_sweepY[0])
    print(f"Stimulus pulse detected at time: {stimuli_time[0]}", flush=True)

    for file_id, data in file_data.items():
        print(f"Processing file: {file_id}", flush=True)
        clamp_sweepY = data['clamp_sweepY']
        clamp_time = data['clamp_time']
        membrane_sweepY = data['membrane_sweepY']

        # Restrict analysis to the selected time interval.
        window_indices = get_window_indices(clamp_time, time_window)

        current = clamp_sweepY[:, window_indices]
        voltage = membrane_sweepY[:, window_indices]
        
        currents.append(current)
        voltages.append(voltage)

    # Use first file timing as the common time axis for regression-by-time outputs.
    first_clamp_time = np.asarray(first_data['clamp_time'], dtype=float)
    window_indices = get_window_indices(first_clamp_time, time_window)
    time_axis_ms = seconds_to_milliseconds(first_clamp_time[window_indices])
    
    currents = np.array(currents)
    voltages = np.array(voltages)
    
    # Average across sweeps (axis 1)
    currents = np.average(currents, axis=1)
    voltages = np.average(voltages, axis=1)

    # Check if voltages are not all identical
    if np.std(voltages) == 0:
        return {
            'slope': 0,
            'intercept': np.mean(currents),
            'r_squared': 0,
            'p_value': 1,
            'outlier_indices': np.array([])
        }
    
    # Estimate leak current and correct currents
    stim_rise_idx = stimuli_time[0] if stimuli_time is not None else None
    leak_current = find_leak_current(currents, voltages, stim_rise_idx)

    leak_slope = leak_current[0]
    leak_intercept = leak_current[1]

    leak_estimated = leak_slope * voltages + leak_intercept
    currents_corrected = currents - leak_estimated

    # Fit regression on leak-corrected currents
    regression = run_regression_over_time(voltages, currents_corrected)

    slopes = regression.slopes
    intercepts = regression.intercepts
    p_values = regression.p_values
    predicteds = regression.predicteds
    r_squareds = regression.r_squareds

    plot_predicted_current_over_time(
        predicteds,
        filename,
        output_dir,
        time_window,
        clamp_channel_labels[1],
        time_axis_ms=time_axis_ms,
    )

    plot_slopes_over_time(
        slopes,
        filename,
        output_dir,
        time_window,
        clamp_channel_labels[1],
        time_axis_ms=time_axis_ms,
    )

    mean_voltages = np.mean(voltages, axis=1)
    mean_currents = np.mean(currents, axis=1)

    # Fit directly on the plotted mean I-V points so fit line and displayed R² match.
    mean_iv_regression = run_regression_over_time(
        mean_voltages[:, np.newaxis],
        mean_currents[:, np.newaxis],
    )
    plot_slope = float(mean_iv_regression.slopes[0])
    plot_intercept = float(mean_iv_regression.intercepts[0])
    plot_p_value = float(mean_iv_regression.p_values[0])
    plot_r_squared = float(mean_iv_regression.r_squareds[0])

    mean_predicteds = plot_slope * mean_voltages + plot_intercept

    plot_iv_relationship(
        mean_voltages,
        mean_currents,
        mean_predicteds,
        plot_r_squared,
        filename,
        output_dir,
        time_window,
        membrane_channel_labels[1],
        clamp_channel_labels[1],
    )

    # Find reversal potential (x-intercept where current = 0)
    # From I = slope * V + intercept, when I = 0: V = -intercept / slope
    reversal_potentials = -intercepts / slopes
    reversal_potential = -plot_intercept / plot_slope
    
    E_e = 0
    E_i = -60

    G_i = (slopes * (E_e - reversal_potentials)) / (E_e - E_i)    
    G_e = slopes - G_i

    plot_Gsyn_Ge_Gi_over_time(
        slopes,
        G_e,
        G_i,
        filename,
        output_dir,
        time_window,
        time_axis_ms=time_axis_ms,
    )

    GeGi_ratio = G_e / G_i
    plot_ei_ratio_over_time(
        GeGi_ratio,
        filename,
        output_dir,
        time_window,
        time_axis_ms=time_axis_ms,
    )

    Ge_fraction = G_e / slopes
    plot_e_fraction_over_time(
        Ge_fraction,
        filename,
        output_dir,
        time_window,
        time_axis_ms=time_axis_ms,
    )
    
    return {
        'slope': plot_slope,
        'intercept': plot_intercept,
        'r_squared': plot_r_squared,
        'p_value': plot_p_value,
        'x-intercept': reversal_potential,
    }

def find_leak_current(currents, voltages, window_end):
    """Backward-compatible wrapper around leak regression helper."""
    return estimate_leak_current(currents, voltages, window_end)

def find_stim_pulse(signal, min_slope=None):
    """Return stimulus pulse indices as (rise_idx, start_idx, end_idx)."""
    y = np.asarray(signal, dtype=float)
    if y.size < 3:
        return None

    # Remove baseline offset for more stable edge detection.
    y = y - np.median(y[: max(5, len(y)//20)])

    dy = np.diff(y)

    rise_idx = int(np.argmax(dy))

    if min_slope is not None and dy[rise_idx] < min_slope:
        return None

    peak = y[rise_idx+1:].max()
    level = 0.5 * peak
    above = np.where(y >= level)[0]
    if len(above) == 0:
        return rise_idx, None

    start = above[0]
    end = above[-1]
    return rise_idx, start, end