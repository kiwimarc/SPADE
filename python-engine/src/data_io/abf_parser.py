import numpy as np
import pyabf

def load_abf(abf_file_path, channel=0):
    """
    Loads an ABF file and extracts time, current matrix, and stimulus waveform.
    channel: channel index to extract (default: 0)
    """
    abf = pyabf.ABF(abf_file_path)
    time = abf.sweepX
    sweepY = []
    
    for sweep_idx in range(abf.sweepCount):
        abf.setSweep(sweep_idx, channel)
        sweepY.append(abf.sweepY)

    return time, np.array(sweepY), (abf.sweepLabelX, abf.sweepLabelY, abf.sweepLabelC)
