import csv


def write_series_csv(csv_path, header, rows):
    """Write tabular data to CSV using standard comma-separated formatting."""
    with open(csv_path, mode="w", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(header)
        writer.writerows(rows)
