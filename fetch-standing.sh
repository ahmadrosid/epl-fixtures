#!/bin/bash
echo "Fetching latest standing stats data..."

# Fetch standing stats
curl --request GET \
  --url 'https://footballapi.pulselive.com/football/standings?compSeasons=578&altIds=true&live=true' \
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
  --header 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36' | jq > standings.json

# Extract the last updated timestamp
TIMESTAMP=$(jq -r '.timestamp.label' standings.json | tr -d '\n')

# Update the "Last updated" timestamp in README.md
sed -i '' "s|**Last updated:.*|**Last updated: $TIMESTAMP**|g" README.md

# Extract standings data into a temporary file
cat standings.json | jq -r '
.tables[0].entries[] |
[
    .position,
    .team.name,
    .overall.played,
    .overall.won,
    .overall.drawn,
    .overall.lost,
    .overall.goalsFor,
    .overall.goalsAgainst,
    .overall.goalsDifference,
    .overall.points
] |
join(" | ")
' | awk 'BEGIN {print "| No | Team | Played | Won | Drawn | Lost | Goals For | Goals Against | Goal Difference | Point |"; print "|----------|------|--------|-----|-------|------|-----------|---------------|-----------------|--------|";} {print "| "$0" |";}' > standings_table.txt


OS=$(uname)
# Delete content between the standings markers in README.md
if [ "$OS" = "Darwin" ]; then
    sed -i '' '/<!-- START_STANDINGS -->/,/<!-- END_STANDINGS -->/{//!d;}' README.md
else
    sed -i '/<!-- START_STANDINGS -->/,/<!-- END_STANDINGS -->/{//!d;}' README.md
fi

# Insert new standings table data after the start marker in README.md
sed -i '' -e '/<!-- START_STANDINGS -->/r standings_table.txt' README.md

# Remove the temporary file
rm standings_table.txt
