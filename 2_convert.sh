#!/bin/bash

# Exit on any error
set -e

source "./0_env.sh"

# Dependencies: jq (to parse JSON)
# Install jq if not already installed: sudo apt-get install jq

# Input JSON file
INPUT_FILE="data/${WEEK_FIRST_DAY}.json"

# Output ICS file for Google Calendar import
OUTPUT_FILE="data/${WEEK_FIRST_DAY}.ics"

# Write ICS header
echo "BEGIN:VCALENDAR" > "${OUTPUT_FILE}"
echo "VERSION:2.0" >> "${OUTPUT_FILE}"
echo "PRODID:-//Your Organization//Your Product//EN" >> "${OUTPUT_FILE}"

# Read the JSON data
DATE_FOR_RASP="$(jq -r '.date_for_rasp' "${INPUT_FILE}")"
START_DATE="$(echo "${DATE_FOR_RASP}" | cut -d' ' -f1 | sed 's/\./-/g')"

# Convert date to YYYY-MM-DD format
TODAY_DATE="$(jq -r '.today_date' "${INPUT_FILE}")"

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

    # Convert short_name to its alias
    alias_name="${alias_map["${short_name}"]}"

    event_summary="${alias_name} - ${subject}"

    # Extract time
    event_start_time="$(echo "${time}" | cut -d' ' -f1)"
    event_end_time="$(echo "${time}" | cut -d' ' -f3)"
    # Remove ":"
    event_start_time="${event_start_time//":"/}"
    event_end_time="${event_end_time//":"/}"

    # Calculate the date for the event
    event_date="$(date -d "${TODAY_DATE} +$((day - 1)) days" "+%Y-%m-%d")"

    event_description="Группы: ${groups}\n\nПреподаватель:\n${teacher}"

    # DEBUG:
    echo "========================================"
    echo "START_DATE: ${START_DATE}"
    echo "TODAY_DATE: ${TODAY_DATE}"
    echo "day: ${day}"
    echo "short_name: ${short_name}"
    echo "alias_name: ${alias_name}"
    echo "subject: ${subject}"
    echo "event_date: ${event_date}"
    echo "event_start_time: ${event_start_time}"
    echo "event_date: ${event_date}"
    echo "event_end_time: ${event_end_time}"
    echo "teacher: ${teacher}"
    echo "location: ${location}"
    echo "groups: ${groups}"

    # Append to ICS
    echo "BEGIN:VEVENT" >> "${OUTPUT_FILE}"
    echo "SUMMARY:${event_summary//\"/}" >> "${OUTPUT_FILE}"
    echo "DTSTART:${event_date//\"/}T${event_start_time//\"/}00" | sed 's/-//g' >> "${OUTPUT_FILE}"
    echo "DTEND:${event_date//\"/}T${event_end_time//\"/}00" | sed 's/-//g' >> "${OUTPUT_FILE}"
    echo "DESCRIPTION:${event_description//\"/}" >> "${OUTPUT_FILE}"
    if [ "${location}" != "DL, Дистанционная" ]; then
        echo "LOCATION:${location//\"/}" >> "${OUTPUT_FILE}"
    fi
    echo "END:VEVENT" >> "${OUTPUT_FILE}"
done

# Write ICS footer
echo "END:VCALENDAR" >> "${OUTPUT_FILE}"
