from dataclasses import dataclass
import importlib
from typing import Optional

import numpy as np


@dataclass
class RegressionSeries:
    slopes: np.ndarray
    intercepts: np.ndarray
    r_squareds: np.ndarray
    p_values: np.ndarray
    predicteds: np.ndarray
    outlier_indices: list[np.ndarray]


def _linregress(x: np.ndarray, y: np.ndarray):
    """Load scipy lazily to avoid static import resolution issues in some editors."""
    scipy_stats = importlib.import_module("scipy.stats")
    return scipy_stats.linregress(x, y)


def get_window_indices(time_values, time_window):
    """Return indices that match a given time window, or all indices if no window is set."""
    if time_window is None:
        return np.arange(len(time_values))

    start_time, end_time = float(time_window[0]), float(time_window[1])
    time_values = np.asarray(time_values, dtype=float)
    return np.where((time_values >= start_time) & (time_values <= end_time))[0]


def run_regression_over_time(voltages: np.ndarray, currents: np.ndarray) -> RegressionSeries:
    """
    Run a linear regression for each time index across files/sweeps.

    Expects both arrays to be shaped as (n_series, n_timepoints).
    """
    slopes = []
    intercepts = []
    r_squareds = []
    p_values = []
    predicteds = []
    outlier_indices = []

    for i in range(currents.shape[1]):
        slope, intercept, r_value, p_value, _ = _linregress(voltages[:, i], currents[:, i])
        predicted = slope * voltages[:, i] + intercept
        residuals = currents[:, i] - predicted
        std_residuals = np.std(residuals)

        if std_residuals == 0:
            outlier_indice = np.array([], dtype=int)
        else:
            outlier_indice = np.where(np.abs(residuals) > 2 * std_residuals)[0]

        slopes.append(slope)
        intercepts.append(intercept)
        r_squareds.append(r_value**2)
        p_values.append(p_value)
        predicteds.append(predicted)
        outlier_indices.append(outlier_indice)

    return RegressionSeries(
        slopes=np.asarray(slopes, dtype=float),
        intercepts=np.asarray(intercepts, dtype=float),
        r_squareds=np.asarray(r_squareds, dtype=float),
        p_values=np.asarray(p_values, dtype=float),
        predicteds=np.asarray(predicteds, dtype=float),
        outlier_indices=outlier_indices,
    )


def average_regression(series: RegressionSeries) -> dict:
    """Compute scalar summary metrics from a RegressionSeries."""
    return {
        "slope": float(np.average(series.slopes)),
        "intercept": float(np.average(series.intercepts)),
        "r_squared": float(np.average(series.r_squareds)),
        "p_value": float(np.average(series.p_values)),
        "predicted": float(np.average(series.predicteds)),
    }


def estimate_leak_current(
    currents: np.ndarray,
    voltages: np.ndarray,
    window_end: Optional[int],
) -> tuple[float, float, float, float, float, list[np.ndarray]]:
    """Estimate leak current regression from pre-stimulus samples."""
    if window_end is None or window_end <= 0:
        window_end = currents.shape[1]

    currents_before_stimulus = currents[:, :window_end]
    voltages_before_stimulus = voltages[:, :window_end]

    leak_series = run_regression_over_time(voltages_before_stimulus, currents_before_stimulus)
    leak_summary = average_regression(leak_series)

    return (
        leak_summary["slope"],
        leak_summary["intercept"],
        leak_summary["r_squared"],
        leak_summary["p_value"],
        leak_summary["predicted"],
        leak_series.outlier_indices,
    )
