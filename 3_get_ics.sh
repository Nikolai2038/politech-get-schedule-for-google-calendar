#!/bin/bash

# Exit on any error
set -e

# Function to convert CSV to ICS
convert_csv_to_ics() {
    csv_file=$1
    ics_file=$2

    # Write ICS header
    echo "BEGIN:VCALENDAR" > "$ics_file"
    echo "VERSION:2.0" >> "$ics_file"
    echo "PRODID:-//Your Organization//Your Product//EN" >> "$ics_file"

    # Read CSV file line by line
    tail -n +2 "$csv_file" | while IFS=, read -r subject start_date start_time end_date end_time description location; do
        # DEBUG:
        echo "========================================"
        echo "subject: ${subject}"
        echo "start_date: ${start_date}"
        echo "start_time: ${start_time}"
        echo "end_date: ${end_date}"
        echo "end_time: ${end_time}"
        echo "description: ${description}"
        echo "location: ${location}"

        echo "BEGIN:VEVENT" >> "$ics_file"
        echo "SUMMARY:${subject//\"/}" >> "$ics_file"
        echo "DTSTART:${start_date//\"/}T${start_time//\"/}" | sed 's/-//g' >> "$ics_file"
        echo "DTEND:${end_date//\"/}T${end_time//\"/}" | sed 's/-//g' >> "$ics_file"
        echo "DESCRIPTION:${description//\"/}" >> "$ics_file"
        echo "LOCATION:${location//\"/}" >> "$ics_file"
        echo "END:VEVENT" >> "$ics_file"
    done

    # Write ICS footer
    echo "END:VCALENDAR" >> "$ics_file"
}

# Usage: convert_csv_to_ics input.csv output.ics
convert_csv_to_ics "./data/2.csv" "./data/3.ics"
