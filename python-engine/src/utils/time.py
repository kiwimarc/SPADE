import numpy as np


def compute_duration_ms(sweep_points: int, sample_rate_hz: float) -> float:
    return (float(sweep_points) / float(sample_rate_hz)) * 1000.0


def build_time_axis_ms(
    n_points: int,
    sample_rate_hz: float | None = None,
    data_points_per_ms: float | None = None,
    start_ms: float = 0.0,
) -> np.ndarray:

    if n_points < 0:
        raise ValueError("n_points must be non-negative")

    if data_points_per_ms is None:
        if sample_rate_hz is None:
            raise ValueError("Provide sample_rate_hz or data_points_per_ms")
        data_points_per_ms = float(sample_rate_hz) / 1000.0

    step_ms = 1.0 / float(data_points_per_ms)
    return float(start_ms) + np.arange(n_points, dtype=float) * step_ms


def seconds_to_milliseconds(values) -> np.ndarray:
    return np.asarray(values, dtype=float) * 1000.0
