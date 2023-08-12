#!/bin/bash

# Check if jq is installed
if ! command -v jq &> /dev/null
then
    echo "jq could not be found. Please install it."
    exit
fi

cat fixtures.json | jq -r '
.content[] |
[
    (.kickoff.label | gsub("^[A-Za-z]+ "; "") | gsub(", [0-9]{4}"; "")),
    .teams[0].team.name,
    (if .teams[0].score then .teams[0].score else "N/A" end),
    .teams[1].team.name,
    (if .teams[1].score then .teams[1].score else "N/A" end),
    (if .status == "C" then "Completed" elif .status == "L" then "Live" else "Upcoming" end)
] |
join(" | ")
' | awk 'BEGIN {print "| Date | Home | Score | Away | Score | Status |"; print "|-------------|--------|--------------|--------|--------------|--------|";} {print "| "$0" |";}' > /tmp/table_data.txt

# Delete content between the markers
sed -i '' '/<!-- START_TABLE -->/,/<!-- END_TABLE -->/{//!d;}' README.md

# Insert new table data after the start marker
sed -i '' -e '/<!-- START_TABLE -->/r /tmp/table_data.txt' README.md

# Remove the temporary file
rm /tmp/table_data.txt
