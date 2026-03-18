import sys
from pathlib import Path
from pyabf import ABF
import os

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
        
        info = f"""
=== ABF File Information ===
File: {filename}
Sampling Rate: {abf.sampleRate} Hz
Number of Sweeps: {abf.sweepCount}
Channels: {abf.channelCount}
Duration: {abf.sweepX[-1]} seconds
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


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python extract_info.py <abf_file> [--save] [--output <path>]")
        sys.exit(1)
    
    file_path = sys.argv[1]
    save_flag = "--save" in sys.argv
    output_file = None
    
    if "--output" in sys.argv:
        idx = sys.argv.index("--output")
        if idx + 1 < len(sys.argv):
            output_file = sys.argv[idx + 1]
    
    extract_abf_info(file_path, save=save_flag, output_path=output_file)