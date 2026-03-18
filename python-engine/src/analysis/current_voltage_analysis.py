import numpy as np

def extract_peak_current(processed_currents, time, time_window, sweep_number=None):
    """
    Extracts peak (maximum absolute) current within a user-defined time window.
    
    Args:
        processed_currents: 2D array of processed current traces (sweeps x timepoints)
        time: time array corresponding to current data
        time_window: tuple of (start_time, end_time) in seconds
        sweep_number: optional specific sweep index to extract (None for all sweeps)
    
    Returns:
        dict mapping sweep indices to {'peak_current', 'peak_time'}
    """
    start_time, end_time = float(time_window[0]), float(time_window[1])
    time = np.asarray(time, dtype=float)
    window_indices = np.where((time >= start_time) & (time <= end_time))[0]
    
    results = {}
    sweep_indices = [int(sweep_number)] if sweep_number is not None else range(len(processed_currents))
    
    for sweep_idx in sweep_indices:
        window_current = processed_currents[sweep_idx][window_indices]
        peak_idx = np.argmax(np.abs(window_current))
        results[sweep_idx] = {
            'peak_current': window_current[peak_idx],
            'peak_time': time[window_indices[peak_idx]]
        }
    
    return results

def extract_integrated_current(processed_currents, time, time_window, sweep_number=None):
    """
    Extracts integrated (summed) current within a user-defined time window.
    
    Args:
        processed_currents: 2D array of processed current traces (sweeps x timepoints)
        time: time array corresponding to current data
        time_window: tuple of (start_time, end_time) in seconds
        sweep_number: optional specific sweep index to extract (None for all sweeps)
    
    Returns:
        dict mapping sweep indices to integrated current value
    """
    start_time, end_time = float(time_window[0]), float(time_window[1])
    time = np.asarray(time, dtype=float)
    window_indices = np.where((time >= start_time) & (time <= end_time))[0]
    
    results = {}
    sweep_indices = [int(sweep_number)] if sweep_number is not None else range(len(processed_currents))
    
    for sweep_idx in sweep_indices:
        window_current = processed_currents[sweep_idx][window_indices]
        dt = np.mean(np.diff(time[window_indices]))
        results[sweep_idx] = np.sum(window_current) * dt
    
    return results

def extract_current_stats(processed_currents, time, time_window, sweep_number=None):
    """
    Extracts multiple statistics (peak, integrated, mean, std) within a time window.
    
    Args:
        processed_currents: 2D array of processed current traces
        time: time array corresponding to current data
        time_window: tuple of (start_time, end_time) in seconds
        sweep_number: optional specific sweep index to extract (None for all sweeps)
    
    Returns:
        dict mapping sweep indices to {'peak', 'integrated', 'mean', 'std'}
    """
    start_time, end_time = float(time_window[0]), float(time_window[1])
    time = np.asarray(time, dtype=float)
    window_indices = np.where((time >= start_time) & (time <= end_time))[0]
    
    results = {}
    sweep_indices = [int(sweep_number)] if sweep_number is not None else range(len(processed_currents))
    
    for sweep_idx in sweep_indices:
        window_current = processed_currents[sweep_idx][window_indices]
        dt = np.mean(np.diff(time[window_indices]))
        
        results[sweep_idx] = {
            'peak': np.max(np.abs(window_current)),
            'integrated': np.sum(window_current) * dt,
            'mean': np.mean(window_current),
            'std': np.std(window_current)
        }
    
    return results
