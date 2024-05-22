#!/bin/bash

# Exit on any error
set -e

# Get JSON data from site and save it to the file
get_json() {
    local input_file="${1}" && { shift || true; }
    if [ -z "${input_file}" ]; then
        echo "Define file path to save JSON!" >&2
        return 1
    fi

    local week_first_day="${1}" && { shift || true; }
    if [ -z "${input_file}" ]; then
        echo "Define week first day in YYYY-MM-DD format!" >&2
        return 1
    fi

    local group_name="${1}" && { shift || true; }
    if [ -z "${input_file}" ]; then
        echo "Define group name!" >&2
        return 1
    fi

    local response
    response="$(curl --silent --show-error 'https://my.spbstu.ru/home/profile/' \
        -X POST \
        -H "X-CSRFToken: ${CSRF_TOKEN}" \
        -H "Cookie: csrftoken=${CSRF_TOKEN}" \
        --data-raw "{\"parameter\":1,\"group_name\":\"\u0432${group_name}\",\"today_date\":\"${week_first_day}\"}")"

    if [ -z "${response}" ]; then
        echo "Response is empty!" >&2
        return 1
    fi

    echo "${response}" | jq > "${input_file}"

    echo "JSON successfully saved to \"${input_file}\"!" >&2

    return 0
}

# Convert JSON file to ICS file
convert_json_to_ics() {
    local input_file="${1}" && { shift || true; }

    if [ ! -f "${input_file}" ]; then
        echo "File \"${input_file}\" does not exist!" >&2
        return 1
    fi

    local output_file="${1}" && { shift || true; }

    # Write ICS header
    echo "BEGIN:VCALENDAR" > "${output_file}"
    echo "VERSION:2.0" >> "${output_file}"
    echo "PRODID:-//Your Organization//Your Product//EN" >> "${output_file}"

    # Read the JSON data
    local today_date
    today_date="$(jq -r '.today_date' "${input_file}")"

    # Create an associative array for short_name to alias conversion
    declare -A alias_map
    while IFS="=" read -r key value; do
        alias_map["$key"]="$value"
    done < <(jq -r '.list_of_name | map("\(. [0])=\(. [1])") | .[]' "${input_file}")

    # Parse JSON and append to CSV
    jq -r '.lessons_for_week[] | select(length > 0) | . as $lesson | .[1:][] | [$lesson[0], .[0], .[1], .[2], .[3], .[4], .[5]] | @csv' "${input_file}" | while IFS=, read -r day time short_name subject groups teacher location; do
        # Remove '"'
        local day="${day//"\""/}"
        local time="${time//"\""/}"
        local short_name="${short_name//"\""/}"
        local subject="${subject//"\""/}"
        local groups="${groups//"\""/}"
        local teacher="${teacher//"\""/}"
        local location="${location//"\""/}"

        # Convert short_name to its alias
        local alias_name="${alias_map["${short_name}"]}"

        local event_summary="${alias_name} - ${subject}"

        # Extract time
        local event_start_time
        event_start_time="$(echo "${time}" | cut -d' ' -f1)"
        local event_end_time
        event_end_time="$(echo "${time}" | cut -d' ' -f3)"
        # Remove ":"
        event_start_time="${event_start_time//":"/}"
        event_end_time="${event_end_time//":"/}"

        # Calculate the date for the event
        local event_date
        event_date="$(date -d "${today_date} +$((day - 1)) days" "+%Y-%m-%d")"

        local event_description="Группы: ${groups}\n\nПреподаватель:\n${teacher}"

        # Append to ICS
        # shellcheck disable=2129
        echo "BEGIN:VEVENT" >> "${output_file}"

        echo "SUMMARY:${event_summary//\"/}" >> "${output_file}"
        echo "DTSTART:${event_date//\"/}T${event_start_time//\"/}00" | sed 's/-//g' >> "${output_file}"
        echo "DTEND:${event_date//\"/}T${event_end_time//\"/}00" | sed 's/-//g' >> "${output_file}"
        echo "DESCRIPTION:${event_description//\"/}" >> "${output_file}"
        if [ "${location}" != "DL, Дистанционная" ]; then
            echo "LOCATION:${location//\"/}" >> "${output_file}"
        fi

        echo "END:VEVENT" >> "${output_file}"
    done

    # Write ICS footer
    echo "END:VCALENDAR" >> "${output_file}"

    echo "JSON successfully converted to \"${output_file}\"!" >&2

    return 0
}

main() {
    # Optional arguments - if they are not defined, use from ".env" file
    local week_first_day="${1:-"${WEEK_FIRST_DAY}"}" && { shift || true; }
    local group_name="${1:-"${GROUP_NAME}"}" && { shift || true; }

    # ========================================
    # Import user's variables
    # ========================================
    if [ ! -f ".env" ]; then
        echo "Create \".env\" file from \".env.example\" and change variables for your needs!" >&2
        return 1
    fi
    # shellcheck source=.env
    source <(sed -E 's/\r$//;s/^\s*([^#].*?)=(.+?)\s*$/export \1=\2/' ".env") > /dev/null
    # ========================================

    # Input JSON file
    input_file="./data/в${group_name//"/"/"-"}_${week_first_day}.json"

    # Output ICS file for Google Calendar import
    output_file="./data/в${group_name//"/"/"-"}_${week_first_day}.ics"

    get_json "${input_file}" "${week_first_day}" "${group_name}"
    convert_json_to_ics "${input_file}" "${output_file}"

    return 0
}

main "$@"
