#!/bin/bash

# Exit on any error
set -e

# Dependencies: jq (to parse JSON)
# Install jq if not already installed: sudo apt-get install jq

# Input JSON file
INPUT_FILE="data/1.json"

# Output CSV file for Google Calendar import
OUTPUT_FILE="data/2.csv"

# Write CSV header
echo "Subject,Start Date,Start Time,End Date,End Time,Description,Location" > "${OUTPUT_FILE}"

# Read the JSON data
DATE_FOR_RASP="$(jq -r '.date_for_rasp' "${INPUT_FILE}")"
START_DATE="$(echo "${DATE_FOR_RASP}" | cut -d' ' -f1 | sed 's/\./-/g')"

# Convert date to YYYY-MM-DD format
TODAY_DATE="$(date -d "20${START_DATE:6:2}-${START_DATE:3:2}-${START_DATE:0:2}" "+%Y-%m-%d")"

# Create an associative array for short_name to alias conversion
declare -A alias_map
while IFS="=" read -r key value; do
    alias_map["$key"]="$value"
done < <(jq -r '.list_of_name | map("\(. [0])=\(. [1])") | .[]' "$INPUT_FILE")

# Parse JSON and append to CSV
jq -r '.lessons_for_week[] | select(length > 0) | . as $lesson | .[1:][] | [$lesson[0], .[0], .[1], .[2], .[3], .[4], .[5]] | @csv' "${INPUT_FILE}" | while IFS=, read -r day time short_name subject groups teacher location; do
    # Remove '"'
    day="${day//"\""/}"
    time="${time//"\""/}"
    short_name="${short_name//"\""/}"
    subject="${subject//"\""/}"
    groups="${groups//"\""/}"
    teacher="${teacher//"\""/}"
    location="${location//"\""/}"

    # Extract time
    START_TIME="$(echo "${time}" | cut -d' ' -f1)"
    END_TIME="$(echo "${time}" | cut -d' ' -f3)"

    # Calculate the date for the event
    EVENT_DATE="$(date -d "${TODAY_DATE} +$((day - 1)) days" "+%Y-%m-%d")"

    # Convert short_name to its alias
    alias_name="${alias_map["${short_name}"]}"

    # DEBUG:
    echo "========================================"
    echo "short_name: ${short_name}"
    echo "alias_name: ${alias_name}"
    echo "subject: ${subject}"
    echo "EVENT_DATE: ${EVENT_DATE}"
    echo "START_TIME: ${START_TIME}"
    echo "EVENT_DATE: ${EVENT_DATE}"
    echo "END_TIME: ${END_TIME}"
    echo "teacher: ${teacher}"
    echo "location: ${location}"
    echo "groups: ${groups}"

    # Append to CSV
    echo "\"${subject}\",\"${EVENT_DATE}\",\"${START_TIME}\",\"${EVENT_DATE}\",\"${END_TIME}\",\"${teacher}, ${alias_name}, Группы: ${groups}\",\"${location}\"" >> "${OUTPUT_FILE}"
done

# Add BOM (Russian text support)
dos2unix --add-bom "${OUTPUT_FILE}"
