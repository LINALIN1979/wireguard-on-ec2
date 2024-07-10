#!/bin/bash

sudo_check() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root or use sudo."
        exit 1
    fi
}

ip_to_number() {
    local IFS=.
    local ip=($1)
    echo $(( (${ip[0]} << 24) + (${ip[1]} << 16) + (${ip[2]} << 8) + ${ip[3]} ))
}

number_to_ip() {
    local ip num=$1
    for e in 1 2 3 4; do
        ip=$(( num & 255 ))${ip:+.${ip}}
        num=$(( num >> 8 ))
    done
    echo $ip
}

add_section() {
    ini_file=$1
    section=$2
    content=$3

    echo -e "\n[$section]\n$content" | tee -a "$ini_file"
}

del_section() {
    ini_file=$1
    section=$2
    temp_file=$(mktemp)

    # Use awk to delete all sections with the specified name
    awk -v section="$section" '
    BEGIN { in_section = 0 }
    /^\[.*\]$/ {
        if ($0 == "[" section "]") {
        in_section = 1
        } else {
        in_section = 0
        }
    }
    !in_section { print }
    ' "$ini_file" > "$temp_file"

    # Replace the original file with the modified one
    mv "$temp_file" "$ini_file"
}

del_section_by_key_value() {
    ini_file=$1
    key=$2
    value=$3
    temp_file=$(mktemp)

    in_section=0
    delete_section=0

    # Process the INI file
    while IFS= read -r line; do
        # Check for section header
        if [[ $line =~ ^\[.*\]$ ]]; then
            if [[ $in_section -eq 1 && $delete_section -eq 0 ]]; then
                echo "$section_content"$'\n' >> "$temp_file"
            fi
            in_section=1
            delete_section=0
            section_content="$line"
        else
            # Inside a section
            if [[ $in_section -eq 1 ]]; then
                if [ ! -z "$line" ]; then
                    section_content="$section_content"$'\n'"$line"
                    # Extract key and value from the line
                    key_value=$(echo "$line" | awk -F '=' '{st=index($0,"="); remaining=substr($0,st+1); gsub(/^[ \t]+|[\t ]+$/, "", $1); gsub(/^[ \t]+|[\t ]+$/, "", remaining); print $1 "=" remaining}')
                    if [[ "$key_value" == "$key=$value" ]]; then
                        delete_section=1
                    fi
                fi
            else
                # Lines outside of sections
                echo "$line" >> "$temp_file"
            fi
        fi
    done < "$ini_file"

    # Handle the last section
    if [[ $in_section -eq 1 && $delete_section -eq 0 ]]; then
        echo "$section_content" >> "$temp_file"
    fi

    # Replace the original file with the modified one
    cp "$temp_file" "$ini_file"
}

find_section_key() {
    ini_file=$1
    section=$2
    key=$3

    # Use awk to find all values for the key in multiple sections with the same name
    values=$(awk -v section="$section" -v key="$key" '
    BEGIN { FS = "="; in_section = 0 }
    /^\[.*\]$/ {
        gsub(/^\[|\]$/, "", $0);
        in_section = ($0 == section) ? 1 : 0;
        next;
    }
    in_section && $1 ~ key {
        gsub(/^[ \t]+|[ \t]+$/, "", $2);
        print $2;
    }
    ' "$ini_file")

    # Check if any values was found
    if [ -n "$values" ]; then
        echo "$values"
    fi
}