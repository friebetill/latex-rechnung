import csv


def read_and_process_csv(file_path):
    # Dictionary to store the total duration per task
    task_durations = {}

    # Read CSV file
    with open(file_path, newline='') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=';')
        for row in reader:
            task = row['task']
            hourly_rate = row['hourly_rate']
            duration_decimal = float(row['duration_decimal'])

            # Check if task already exists in the dictionary
            if task not in task_durations:
                task_durations[task] = {
                    'hourly_rate': hourly_rate,
                    'total_duration': 0.0
                }

            # Accumulate the duration
            task_durations[task]['total_duration'] += duration_decimal

    # Generate and print the output


    print("\\newcommand{\\fees}{")
    for task, data in task_durations.items():
        escaped_task = task.replace('%', '\\%')
        print(f"  \\Fee{{{escaped_task}}}{{{data['hourly_rate']}}}{{{data['total_duration']:.2f}}}")
    print("}")

    # % Auslagen
	# %\EBCi{Hotel, 12 Nächte} {2400.00}
	# %\STExpenses

	# % Rabatt
	# % \Discount{Rabatt}{20}


# Example usage
file_path = 'timemator_data.csv'  # Replace this with the actual path to your CSV file
read_and_process_csv(file_path)

