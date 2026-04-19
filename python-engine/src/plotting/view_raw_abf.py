import os
import matplotlib.pyplot as plt

from src.data_io.csv_writer import write_series_csv as _write_series_csv

def plot_raw_data(time, sweepY, filename, output_dir, channel, channel_labels, sweep_number=None, start_time=None, end_time=None, export_format="png", export_csv=False):
    """
    Plots raw electrophysiology recordings from ABF files.
    
    Args:
        time: Time array for the x-axis
        sweepY: 2D array of current measurements (sweeps x time points)
        filename: Name of the source ABF file
        output_dir: Directory to save the plot image
        channel: Channel number being plotted
        channel_labels: Labels for channels
        sweep_number: Optional specific sweep to plot; if None, plots all sweeps
        start_time: Optional start time for zooming (seconds)
        end_time: Optional end time for zooming (seconds)
        export_format: Format for exporting the plot (supported formats: eps, jpeg, jpg, pdf, pgf, png, ps, raw, rgba, svg, svgz, tif, tiff, webp)
        export_csv: If True, exports data to CSV instead of saving a plot
    Returns:
        str: File path to the saved plot image or CSV file
    """
    # Determine which sweeps to process
    sweeps_to_plot = [int(sweep_number)] if sweep_number is not None else range(len(sweepY))
    
    # Prepare output directory and common filename suffixes
    os.makedirs(output_dir, exist_ok=True)
    sweep_suffix = f"_raw_plot_sweep_{sweep_number}" if sweep_number is not None else "_raw_plot"
    zoom_suffix = f"_t{start_time}-{end_time}" if start_time is not None and end_time is not None else ""

    if export_csv:
        csv_filename = filename.replace('.abf', f'{sweep_suffix}{zoom_suffix}_channel_{channel}.csv')
        csv_path = os.path.join(output_dir, csv_filename)
        
        # Apply time mask if zoom is specified
        if start_time is not None and end_time is not None:
            s_time, e_time = float(start_time), float(end_time)
            time_mask = (time >= s_time) & (time <= e_time)
            out_time = time[time_mask]
            out_sweeps = [sweepY[sweep][time_mask] for sweep in sweeps_to_plot]
        else:
            out_time = time
            out_sweeps = [sweepY[sweep] for sweep in sweeps_to_plot]

        header = ['Time'] + [f'Sweep_{sweep}' for sweep in sweeps_to_plot]
        _write_series_csv(csv_path, header, zip(out_time, *out_sweeps))
                
        return csv_path

    # Set up the plot
    fig, ax1 = plt.subplots(figsize=(10, 6))
    
    # Set colormap for better visualization of multiple sweeps
    colormap = plt.get_cmap('cool')
    colors = [colormap(x/len(sweepY)) for x in range(len(sweepY))]

    # Loop through sweeps and plot them
    for idx, sweep in enumerate(sweeps_to_plot):
        dataX = time + .025 * idx
        dataY = sweepY[sweep] + 40 * idx
        
        ax1.plot(dataX, dataY, color=colors[sweep], alpha=.5)
    
    # Format the charts
    sweep_label = f" - Sweep {sweep_number}" if sweep_number is not None else ""
    
    ax1.set_title(f"Raw Recording: {filename}{sweep_label}")
    ax1.set_xlabel(channel_labels[0])
    ax1.set_ylabel(channel_labels[1])
    ax1.grid(True, alpha=0.3)

    # Apply time zoom if specified
    if start_time is not None and end_time is not None:
        s_time, e_time = float(start_time), float(end_time)
        ax1.set_xlim(s_time, e_time)
        
        time_mask = (dataX >= s_time) & (dataX <= e_time)
        y_in_range = dataY[time_mask]

        if len(y_in_range) > 0:
            ax1.set_ylim(min(y_in_range)-10, max(y_in_range)+10)

    plt.tight_layout()
    
    # Save the plot
    plot_filename = filename.replace('.abf', f'{sweep_suffix}{zoom_suffix}_channel_{channel}.{export_format}')
    plot_path = os.path.join(output_dir, plot_filename)
    plt.savefig(plot_path, dpi=300, format=export_format)
    plt.close()
    
    return plot_path