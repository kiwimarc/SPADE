import os

import matplotlib.pyplot as plt


def _zoom_suffix(time_window):
    if time_window is None:
        return ""
    return f"_t{time_window[0]}-{time_window[1]}"


def _safe_plot_filename(filename, suffix):
    return filename.replace(".abf", suffix).replace("*", "%")


def plot_predicted_current_over_time(predicteds, filename, output_dir, time_window, y_label):
    zoom_suffix = _zoom_suffix(time_window)

    plt.figure(figsize=(10, 5))
    plt.grid(alpha=0.5, ls="--")
    plt.plot(predicteds, ".-", ms=8, alpha=0.7)
    plt.xlabel("Time Index")
    plt.ylabel(y_label)
    plt.title(f"Predicted Current Over Time - {filename}")

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_predicted_current.png")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight")
    plt.close()


def plot_slopes_over_time(slopes, filename, output_dir, time_window, y_label):
    zoom_suffix = _zoom_suffix(time_window)

    plt.figure(figsize=(10, 5))
    plt.grid(alpha=0.5, ls="--")
    plt.plot(slopes, ".-", ms=8, alpha=0.7)
    plt.xlabel("Time Index")
    plt.ylabel(y_label)
    plt.title(f"Slopes Over Time - {filename}")

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_slopes.png")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight")
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

    plot_filename = _safe_plot_filename(filename, f"{zoom_suffix}_iv_analysis.png")
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=150, bbox_inches="tight")
    plt.close()
