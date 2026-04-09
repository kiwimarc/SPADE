import os

import matplotlib.pyplot as plt
import numpy as np


def _zoom_suffix(time_window):
    if time_window is None:
        return ""
    return f"_t{time_window[0]}-{time_window[1]}"


def _safe_plot_filename(filename, suffix):
    return filename.replace(".abf", suffix).replace("*", "%")


def _resolve_x_axis(values, time_axis_ms):
    values = np.asarray(values)
    if time_axis_ms is None:
        return np.arange(values.shape[0], dtype=float), "Points"

    x_axis = np.asarray(time_axis_ms, dtype=float)
    if x_axis.shape[0] != values.shape[0]:
        raise ValueError("time_axis_ms length must match the first dimension of plotted values")
    return x_axis, "Time (ms)"


def plot_predicted_current_over_time(
    predicteds,
    filename,
    output_dir,
    time_window,
    y_label,
    time_axis_ms=None,
    export_format="png"
):
    zoom_suffix = _zoom_suffix(time_window)
    x_axis, x_label = _resolve_x_axis(predicteds, time_axis_ms)

    plt.figure(figsize=(10, 5))
    plt.grid(alpha=0.5, ls="--")
    plt.plot(x_axis, predicteds, ".-", ms=0.1, alpha=0.7)
    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.title(f"Predicted Current Over Time - {filename}")

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_predicted_current.{export_format}")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight", format=export_format)
    plt.close()


def plot_slopes_over_time(slopes, filename, output_dir, time_window, y_label, time_axis_ms=None, export_format="png"):
    zoom_suffix = _zoom_suffix(time_window)
    x_axis, x_label = _resolve_x_axis(slopes, time_axis_ms)

    plt.figure(figsize=(10, 5))
    plt.grid(alpha=0.5, ls="--")
    plt.plot(x_axis, slopes, ".-", ms=0.1, alpha=0.7)
    plt.xlabel(x_label)
    plt.ylabel("Slope (nS)")
    plt.title(f"Slopes Over Time - {filename}")

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_slopes.{export_format}")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight", format=export_format)
    plt.close()


def plot_iv_relationship(
    mean_voltages,
    mean_currents,
    mean_predicteds,
    r_squared,
    filename,
    output_dir,
    time_window,
    x_label,
    y_label,
    export_format="png"
):
    zoom_suffix = _zoom_suffix(time_window)

    plt.figure(figsize=(8, 5))
    plt.grid(alpha=0.5, ls="--")
    plt.plot(mean_voltages, mean_currents, ".-", ms=10, label="Data", color="blue")
    plt.plot(mean_voltages, mean_predicteds, "--", color="red", label=f"Fit (R² = {r_squared:.3f})")
    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.title(f"I/V Relationship of {filename}\nR² = {r_squared:.4f}")
    plt.legend()

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_iv_analysis.{export_format}")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight", format=export_format)
    plt.close()

def plot_Gsyn_Ge_Gi_over_time(
    G_syn,
    G_e,
    G_i,
    filename,
    output_dir,
    time_window,
    time_axis_ms=None,
    export_format="png"
):
    zoom_suffix = _zoom_suffix(time_window)
    x_axis, x_label = _resolve_x_axis(G_syn, time_axis_ms)

    plt.figure(figsize=(10, 5))
    plt.grid(alpha=0.5, ls="--")
    plt.plot(x_axis, G_syn, ".-", ms=0.1, alpha=0.7, label="G_syn", color="green")
    plt.plot(x_axis, G_e, ".-", ms=0.1, alpha=0.7, label="G_e", color="#ff0000")
    plt.plot(x_axis, G_i, ".-", ms=0.1, alpha=0.7, label="G_i", color="#0000ff")
    plt.xlabel(x_label)
    plt.ylabel("Conductance (nS)")
    plt.title(f"Estimated G_syn, G_e and G_i Over Time - {filename}")
    plt.legend()

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_Gsyn_Ge_Gi_over_time.{export_format}")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight", format=export_format)
    plt.close()

def plot_ei_ratio_over_time(EI_ratio, filename, output_dir, time_window, time_axis_ms=None, export_format="png"):
    zoom_suffix = _zoom_suffix(time_window)
    x_axis, x_label = _resolve_x_axis(EI_ratio, time_axis_ms)

    plt.figure(figsize=(10, 5))
    plt.fill_between(x_axis, 0, EI_ratio, color="#ff0000")
    plt.fill_between(x_axis, EI_ratio, 1, color="#0000ff")
    plt.ylim(0, 1)
    plt.xlabel(x_label)
    plt.ylabel("E/I Ratio")
    plt.title(f"E/I Ratio Over Time - {filename}")

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_EI_ratio_over_time.{export_format}")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight", format=export_format)
    plt.close()

def plot_e_fraction_over_time(E_fraction , filename, output_dir, time_window, time_axis_ms=None, export_format="png"):
    zoom_suffix = _zoom_suffix(time_window)
    x_axis, x_label = _resolve_x_axis(E_fraction, time_axis_ms)

    plt.figure(figsize=(10, 5))
    plt.fill_between(x_axis, 0, E_fraction, color="#ff0000")
    plt.ylim(0, 1)
    plt.xlabel(x_label)
    plt.ylabel("E Fraction")
    plt.title(f"E Fraction Over Time - {filename}")

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_E_fraction_over_time.{export_format}")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight", format=export_format)
    plt.close()