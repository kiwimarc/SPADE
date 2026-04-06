from pathlib import Path
from pyabf import ABF
import os

from src.utils.time import compute_duration_ms

def extract_abf_info(file_path: str, save: bool = False, output_path: str = None) -> str:
    """
    Extract information from an ABF file.
    
    Args:
        file_path: Path to the ABF file
        save: Whether to save output to a text file
        output_path: Path for the output text file (optional)
    
    Returns:
        Extracted information as string
    """
    try:
        abf = ABF(file_path)
        filename = os.path.basename(file_path)
        sweep_points = len(abf.sweepX)
        duration_ms = compute_duration_ms(sweep_points, abf.sampleRate)
        
        info = f"""
=== ABF File Information ===
File: {filename}
Sampling Rate: {abf.sampleRate} Hz
Number of Sweeps: {abf.sweepCount}
Channels: {abf.channelCount}
Duration: {abf.sweepX[-1]} seconds
Duration: {duration_ms:.3f} ms
Protocol: {abf.protocol}
Dac Channels: {abf.dacNames}
Dac Units: {abf.dacUnits}
DataPoints Per ms: {abf.dataPointsPerMs}
===========================
        """
        
        # Print to terminal
        print(info)
        
        # Save to file if requested
        if save:
            if output_path is None:
                output_path = Path(file_path).stem + "_info.txt"
            
            with open(output_path, 'w') as f:
                f.write(info)
            print(f"\nInfo saved to: {output_path}")
        
        return info
    
    except Exception as e:
        print(f"Error reading ABF file: {e}")
        return None