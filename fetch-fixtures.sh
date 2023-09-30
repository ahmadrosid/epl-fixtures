#!/bin/bash
echo "Fetching latest fixtures data..."

curl --request GET \
    --url 'https://footballapi.pulselive.com/football/fixtures?statuses=U,L,C&pageSize=20&startDate=2023-09-30&endDate=2023-10-03&page=0&altIds=true&comps=1' \
    --header 'accept: */*' \
    --header 'accept-language: en-US,en;q=0.9,id-ID;q=0.8,id;q=0.7' \
    --header 'authority: footballapi.pulselive.com' \
    --header 'content-type: application/x-www-form-urlencoded; charset=UTF-8' \
    --header 'if-none-match: W/"03b2b9bb2d61e889c39f3fa9353769d4a"' \
    --header 'origin: https://www.premierleague.com' \
    --header 'referer: https://www.premierleague.com/' \
    --header 'sec-ch-ua: "Not/A)Brand";v="99", "Google Chrome";v="115", "Chromium";v="115"' \
    --header 'sec-ch-ua-mobile: ?0' \
    --header 'sec-ch-ua-platform: "macOS"' \
    --header 'sec-fetch-dest: empty' \
    --header 'sec-fetch-mode: cors' \
    --header 'sec-fetch-site: cross-site' \
    --header 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36' | jq > fixtures.json

cat fixtures.json | jq -r '
.content[] |
[
    (.kickoff.label | gsub("^[A-Za-z]+ "; "") | gsub(", [0-9]{4}"; "") | gsub(" BST"; "") | gsub(" 2023"; "")),
    .teams[0].team.name,
    (if .teams[0].score then .teams[0].score else "N/A" end),
    .teams[1].team.name,
    (if .teams[1].score then .teams[1].score else "N/A" end),
    (if .status == "C" then "Completed" elif .status == "L" then "Live" else "Upcoming" end)
] |
join(" | ")
' | awk 'BEGIN {print "| Date | Home | Score | Away | Score | Status |"; print "|-------------|--------|--------------|--------|--------------|--------|";} {print "| "$0" |";}' > table_data.txt

OS=$(uname)
# Delete content between the markers
if [ "$OS" = "Darwin" ]; then
    sed -i '' '/<!-- START_TABLE -->/,/<!-- END_TABLE -->/{//!d;}' README.md
else
    sed -i '/<!-- START_TABLE -->/,/<!-- END_TABLE -->/{//!d;}' README.md
fi

# Insert new table data after the start marker
sed -i '' -e '/<!-- START_TABLE -->/r table_data.txt' README.md

# Remove the temporary file
rm table_data.txt
