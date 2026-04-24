import os

import matplotlib.pyplot as plt
import numpy as np


def _zoom_suffix(time_window):
    if time_window is None:
        return ""
    return f"_t{time_window[0]}-{time_window[1]}"


def _safe_plot_filename(filename, suffix):
    return filename.replace('"', '').replace(".abf", suffix).replace("*", "%")


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
    """Plot predicted current over time and save the figure.

    Args:
        predicteds: Predicted current series.
        filename: Source filename used in figure title and output naming.
        output_dir: Directory where the output figure is written.
        time_window: Optional tuple used for output filename suffix.
        y_label: Label for the y-axis.
        time_axis_ms: Optional time axis in milliseconds.
        export_format: Format for exporting the plot (supported formats: eps, jpeg, jpg, pdf, pgf, png, ps, raw, rgba, svg, svgz, tif, tiff, webp)

    Returns:
        None: The figure is saved to disk and not returned.
    """
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
    """Plot slope values over time and save the figure.

    Args:
        slopes: Slope values over time.
        filename: Source filename used in figure title and output naming.
        output_dir: Directory where the output figure is written.
        time_window: Optional tuple used for output filename suffix.
        y_label: Unused compatibility argument kept for call-site stability.
        time_axis_ms: Optional time axis in milliseconds.
        export_format: Format for exporting the plot (supported formats: eps, jpeg, jpg, pdf, pgf, png, ps, raw, rgba, svg, svgz, tif, tiff, webp)

    Returns:
        None: The figure is saved to disk and not returned.
    """
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
    """Plot mean I-V points with fitted predictions and save the figure.

    Args:
        mean_voltages: Mean membrane voltages used for x-axis values.
        mean_currents: Mean measured currents used as observed y values.
        mean_predicteds: Predicted currents from the fit.
        r_squared: Goodness-of-fit metric used in title and legend.
        filename: Source filename used in figure title and output naming.
        output_dir: Directory where the output figure is written.
        time_window: Optional tuple used for output filename suffix.
        x_label: Label for the x-axis.
        y_label: Label for the y-axis.
        export_format: Format for exporting the plot (supported formats: eps, jpeg, jpg, pdf, pgf, png, ps, raw, rgba, svg, svgz, tif, tiff, webp)

    Returns:
        None: The figure is saved to disk and not returned.
    """
    zoom_suffix = _zoom_suffix(time_window)

    plt.figure(figsize=(8, 5))
    plt.grid(alpha=0.5, ls="--")

    # Warn if fit quality is low, and change the plot color to indicate potential issues with the fit
    if r_squared < 0.95:
        print(f"Warning: Low R² value ({r_squared:.4f}) for I-V fit in {filename}.")
        plt.plot(mean_voltages, mean_currents, ".-", ms=10, label="Data", color="red")
    else:
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
    """Plot conductance components over time and save the figure.

    Args:
        G_syn: Total synaptic conductance values.
        G_e: Excitatory conductance values.
        G_i: Inhibitory conductance values.
        filename: Source filename used in figure title and output naming.
        output_dir: Directory where the output figure is written.
        time_window: Optional tuple used for output filename suffix.
        time_axis_ms: Optional time axis in milliseconds.
        export_format: Format for exporting the plot (supported formats: eps, jpeg, jpg, pdf, pgf, png, ps, raw, rgba, svg, svgz, tif, tiff, webp)

    Returns:
        None: The figure is saved to disk and not returned.
    """
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
    """Plot the E/I ratio trace over time and save the figure.

    Args:
        EI_ratio: Excitatory-to-inhibitory ratio values.
        filename: Source filename used in figure title and output naming.
        output_dir: Directory where the output figure is written.
        time_window: Optional tuple used for output filename suffix.
        time_axis_ms: Optional time axis in milliseconds.
        export_format: Format for exporting the plot (supported formats: eps, jpeg, jpg, pdf, pgf, png, ps, raw, rgba, svg, svgz, tif, tiff, webp)

    Returns:
        None: The figure is saved to disk and not returned.
    """
    zoom_suffix = _zoom_suffix(time_window)
    x_axis, x_label = _resolve_x_axis(EI_ratio, time_axis_ms)

    plt.figure(figsize=(10, 5))
    plt.plot(x_axis, EI_ratio, ".-", ms=0.1, alpha=0.7)
    #plt.fill_between(x_axis, 0, EI_ratio, color="#ff0000")
    #plt.fill_between(x_axis, EI_ratio, 1, color="#0000ff")
    plt.ylim(0, 1)
    plt.xlabel(x_label)
    plt.ylabel("E/I Ratio")
    plt.title(f"E/I Ratio Over Time - {filename}")

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_EI_ratio_over_time.{export_format}")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight", format=export_format)
    plt.close()

def plot_e_and_i_fraction_over_time(E_fraction, I_fraction, filename, output_dir, time_window, time_axis_ms=None, export_format="png"):
    """Plot the excitatory and inhibitory fraction traces over time and save the figure.

    Args:
        E_fraction: Excitatory fraction values.
        I_fraction: Inhibitory fraction values.
        filename: Source filename used in figure title and output naming.
        output_dir: Directory where the output figure is written.
        time_window: Optional tuple used for output filename suffix.
        time_axis_ms: Optional time axis in milliseconds.
        export_format: Format for exporting the plot (supported formats: eps, jpeg, jpg, pdf, pgf, png, ps, raw, rgba, svg, svgz, tif, tiff, webp)

    Returns:
        None: The figure is saved to disk and not returned.
    """
    zoom_suffix = _zoom_suffix(time_window)
    x_axis, x_label = _resolve_x_axis(E_fraction, time_axis_ms)

    plt.figure(figsize=(10, 5))
    plt.fill_between(x_axis, 0, E_fraction, color="#ff0000", label="E Fraction")
    plt.fill_between(x_axis, 0, I_fraction, color="#0000ff", label="I Fraction")
    plt.ylim(0, 1)
    plt.xlabel(x_label)
    plt.ylabel("E & I Fraction")
    plt.title(f"E and I Fractions Over Time - {filename}")
    plt.legend()

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_E_and_I_fraction_over_time.{export_format}")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight", format=export_format)
    plt.close()