import numpy as np
import pyabf

def load_abf(abf_file_path, channel=0):
    """
    Load an ABF file and extract sweep data for one channel.

    Args:
        abf_file_path: Path to the ABF file.
        channel: Channel index to read.

    Returns:
        tuple: ``(time, sweep_matrix, channel_labels)`` where ``time`` is 1D,
            ``sweep_matrix`` is ``(n_sweeps, n_points)``, and ``channel_labels``
            is ``(x_label, y_label, c_label)``.
    """
    abf = pyabf.ABF(abf_file_path)
    time = abf.sweepX
    sweepY = []
    
    for sweep_idx in range(abf.sweepCount):
        abf.setSweep(sweep_idx, channel)
        sweepY.append(abf.sweepY)

    return time, np.array(sweepY), (abf.sweepLabelX, abf.sweepLabelY, abf.sweepLabelC)
