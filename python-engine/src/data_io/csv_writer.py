import csv


def write_series_csv(csv_path, header, rows):
    """Write tabular data to a CSV file.

    Args:
        csv_path: Destination CSV file path.
        header: Iterable of column names.
        rows: Iterable of row iterables.

    Returns:
        None: Data is written to disk.
    """
    with open(csv_path, mode="w", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(header)
        writer.writerows(rows)
