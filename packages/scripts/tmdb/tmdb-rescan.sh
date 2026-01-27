#!/bin/bash
VER=1.0
#--[ Info ]-----------------------------------------------------
# 
# TMDB Movie Rescanner by Teqno
#
# This script comes without any warranty, use it at your own risk.
#
# Get an API key from: https://www.themoviedb.org/settings/api
#
#--[ Settings ]-------------------------------------------------

TMDB_API_KEY=""
GLROOT="/glftpd"
SECTIONS="
/site/X264-1080
/site/ARCHIVE/X264-1080
"
DRY_RUN=false
TIMESTAMP_ONLY=false

#--[ Script Start ]---------------------------------------------

lockfile="$GLROOT$tmp/tmdb-rescan.lock"

# Improved cleanup function
cleanup()
{

    [[ -f "$GLROOT$tmp/tmdb-rescan.tmp" ]] && rm -f "$GLROOT$tmp/tmdb-rescan.tmp"
    [[ -f "$lockfile" ]] && rm -f "$lockfile"
    exit

}

# Set trap to clean up on normal exit or signals
trap cleanup EXIT INT TERM

# Check if lockfile exists and contains a running process
if [[ -e "$lockfile" ]]
then

    if read -r pid < "$lockfile" && kill -0 "$pid" 2>/dev/null
    then

        echo "Process $pid is still running with lockfile $lockfile. Quitting."
        exit 0

    else

        echo "Stale lockfile found. Removing and continuing."
        rm -f "$lockfile"

    fi

fi

# Create lockfile with current PID
echo $$ > "$lockfile"

# Colors
if command -v tput > /dev/null; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)
else
    RED=''; GREEN=''; YELLOW=''; RESET=''
fi



# Parse arguments
for arg in "$@"; do
    case $arg in
        -d|--dry-run) DRY_RUN=true ;;
        -r=*) GLROOT="${arg#*=}" ;;
        -s=*) SECTIONS="${arg#*=}" ;;
        -t|--timestamp-only) TIMESTAMP_ONLY=true ;;
        -h|--help)
			echo "Usage: $0 [-d] [-t] [-r=/path] [-s=\"section1 section2\"]"
            echo "  -t, --timestamp-only  Only restore timestamps without creating files"
            exit 0
            ;;
    esac
done

# Check API key
if [[ "$TMDB_API_KEY" == "YOUR_TMDB_API_KEY_HERE" ]]; then
    echo "${RED}Error: Set your TMDB API key in the script${RESET}"
    exit 1
fi

# Function to restore directory timestamp using reference file
restore_dir_timestamp() {
    local dir="$1"

    # Look for .nfo file to use as timestamp reference (first priority)
    local ref_file=""
    for f in "$dir"/*.nfo; do
        if [[ -f "$f" ]]; then
            ref_file="$f"
            break
        fi
    done

    # Fallback to .rar file if no .nfo found (second priority)
    if [[ -z "$ref_file" ]]; then
        for f in "$dir"/*.rar; do
            if [[ -f "$f" ]]; then
                ref_file="$f"
                break
            fi
        done
    fi

    # Restore directory timestamp using reference file
    if [[ -n "$ref_file" ]]; then
        if [[ "$DRY_RUN" == false ]]; then
            touch -r "$ref_file" "$dir"
            echo "    ${GREEN}Restored timestamp from: $(basename "$ref_file")${RESET}"
        else
            echo "    ${YELLOW}Would restore timestamp from: $(basename "$ref_file")${RESET}"
        fi
    else
        echo "    ${YELLOW}No reference file (.rar or .nfo) found${RESET}"
    fi
}

# Extract movie title and year from folder name
extract_movie_info() {
    local folder="$1"
    
    # Remove group name (everything after last dash)
    folder="${folder%-*}"
    
    # Look for pattern: Title.Year.Quality
    if [[ "$folder" =~ ^(.*)\.((19|20)[0-9]{2})\..+$ ]]; then
        # Has quality info after year
        echo "${BASH_REMATCH[1]}|${BASH_REMATCH[2]}"
    elif [[ "$folder" =~ ^(.*)\.((19|20)[0-9]{2})$ ]]; then
        # Year at the end
        echo "${BASH_REMATCH[1]}|${BASH_REMATCH[2]}"
    else
        # No year found
        echo "$folder|"
    fi
}

# Clean title for API
clean_title() {
    local title="$1"
    # Remove dots, replace with spaces
    title="${title//./ }"
    # Remove special characters, keep letters, numbers, spaces
    title=$(echo "$title" | tr -cd '[:alnum:][:space:]')
    echo "$title"
}

# Search TMDB
search_tmdb() {
    local title="$1"
    local year="$2"
    
    # URL encode
    local query="${title// /%20}"
    local url="https://api.themoviedb.org/3/search/movie?api_key=$TMDB_API_KEY&query=$query&include_adult=false"
    
    [[ -n "$year" ]] && url="$url&year=$year"
    
    # Get first result
    local response=$(curl -s "$url")
    local movie_id=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    
    if [[ -z "$movie_id" ]]; then
        # Try without year
        if [[ -n "$year" ]]; then
            url="https://api.themoviedb.org/3/search/movie?api_key=$TMDB_API_KEY&query=$query&include_adult=false"
            response=$(curl -s "$url")
            movie_id=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
        fi
    fi
    
    echo "$movie_id"
}

# Get movie details - WORKING VERSION
get_movie_details() {
    local movie_id="$1"
    
    local url="https://api.themoviedb.org/3/movie/$movie_id?api_key=$TMDB_API_KEY&append_to_response=credits"
    local response=$(curl -s "$url")
    
    # Extract basic data
    local title=$(echo "$response" | sed -n 's/.*"title":"\([^"]*\)".*/\1/p')
    local release_date=$(echo "$response" | sed -n 's/.*"release_date":"\([^"]*\)".*/\1/p')
    local year=$(echo "$release_date" | cut -d'-' -f1)
    local rating=$(echo "$response" | sed -n 's/.*"vote_average":\([0-9.]*\).*/\1/p')
    local overview=$(echo "$response" | sed -n 's/.*"overview":"\([^"]*\)".*/\1/p')
    local runtime=$(echo "$response" | sed -n 's/.*"runtime":\([0-9]*\).*/\1/p')
    local imdb_id=$(echo "$response" | sed -n 's/.*"imdb_id":"\([^"]*\)".*/\1/p')
    
    # EXTRACT GENRES - WORKING
    local genres=""
    if echo "$response" | grep -q '"genres":'; then
        local genres_part=$(echo "$response" | sed 's/.*"genres":\[//')
        local bracket_count=1
        local genres_json=""
        for ((i=0; i<${#genres_part}; i++)); do
            char="${genres_part:$i:1}"
            if [[ "$char" == "[" ]]; then
                ((bracket_count++))
            elif [[ "$char" == "]" ]]; then
                ((bracket_count--))
                if [[ $bracket_count -eq 0 ]]; then
                    genres_json="${genres_part:0:$i}"
                    break
                fi
            fi
        done
        genres=$(echo "$genres_json" | grep -o '"name":"[^"]*"' | sed 's/"name":"\([^"]*\)"/\1/g' | head -3 | tr '\n' '_' | sed 's/_$//')
    fi
    
    # EXTRACT CAST - WORKING
    local cast=""
    if echo "$response" | grep -q '"cast":'; then
        local cast_part=$(echo "$response" | sed 's/.*"cast":\[//')
        local cast_bracket_count=1
        local cast_json=""
        for ((i=0; i<${#cast_part}; i++)); do
            char="${cast_part:$i:1}"
            if [[ "$char" == "[" ]]; then
                ((cast_bracket_count++))
            elif [[ "$char" == "]" ]]; then
                ((cast_bracket_count--))
                if [[ $cast_bracket_count -eq 0 ]]; then
                    cast_json="${cast_part:0:$i}"
                    break
                fi
            fi
        done
        cast=$(echo "$cast_json" | grep -o '"name":"[^"]*"' | sed 's/"name":"\([^"]*\)"/\1/g' | head -5 | tr '\n' ',' | sed 's/,/, /g; s/, $//')
    fi
    
	# Function to convert country code to full name
	convert_country_code() {
	    local country_code="$1"
	    
	    if [[ -z "$country_code" ]] || [[ "$country_code" == "N/A" ]]; then
		echo "N/A"
		return
	    fi
	    
	    # Use REST Countries API
	    local country_info=$(curl -s "https://restcountries.com/v3.1/alpha/$country_code")
	    
	    if [[ -n "$country_info" ]] && ! echo "$country_info" | grep -q "Not Found"; then
		# Extract the common name
		local country_name=$(echo "$country_info" | grep -o '"common":"[^"]*"' | head -1 | cut -d'"' -f4)
		echo "$country_name"
	    else
		# If API fails, return the code
		echo "$country_code"
	    fi
	}

	# EXTRACT COUNTRY - from origin_country
	local country="N/A"
	if echo "$response" | grep -q '"origin_country":'; then
	    local country_part=$(echo "$response" | sed 's/.*"origin_country":\[//')
	    local country_bracket_count=1
	    local country_json=""
	    for ((i=0; i<${#country_part}; i++)); do
		char="${country_part:$i:1}"
		if [[ "$char" == "[" ]]; then
		    ((country_bracket_count++))
		elif [[ "$char" == "]" ]]; then
		    ((country_bracket_count--))
		    if [[ $country_bracket_count -eq 0 ]]; then
			country_json="${country_part:0:$i}"
			break
		    fi
		fi
	    done
	    
	    # origin_country contains country codes like ["US", "GB"]
	    local country_code=$(echo "$country_json" | grep -o '"[A-Z][A-Z]"' | head -1 | tr -d '"')
	    
	    if [[ -n "$country_code" ]]; then
		# Convert code to full name using REST Countries API
		country=$(convert_country_code "$country_code")
	    fi
	fi

	# Fallback to production_countries if origin_country not found or empty
	if [[ "$country" == "N/A" ]] || [[ -z "$country" ]] || [[ "$country" == "$country_code" ]]; then
	    if echo "$response" | grep -q '"production_countries":'; then
		local country_part=$(echo "$response" | sed 's/.*"production_countries":\[//')
		local country_bracket_count=1
		local country_json=""
		for ((i=0; i<${#country_part}; i++)); do
		    char="${country_part:$i:1}"
		    if [[ "$char" == "[" ]]; then
			((country_bracket_count++))
		    elif [[ "$char" == "]" ]]; then
			((country_bracket_count--))
			if [[ $country_bracket_count -eq 0 ]]; then
			    country_json="${country_part:0:$i}"
			    break
			fi
		    fi
		done
		country=$(echo "$country_json" | grep -o '"name":"[^"]*"' | sed 's/"name":"\([^"]*\)"/\1/g' | head -1)
	    fi
	fi
    
    # EXTRACT SPOKEN LANGUAGES - using spoken_languages array
    local language="N/A"

    # Check if spoken_languages array exists in response
    if echo "$response" | grep -q '"spoken_languages":\['; then
        # Extract all english_name fields from spoken_languages array
        local languages=$(echo "$response" |
        sed -n '/"spoken_languages":\[/,/\],/p' |  # Get the spoken_languages array block
        grep '"english_name"' |                    # Find all english_name lines
        sed 's/.*"english_name":"\([^"]*\)".*/\1/' |  # Extract the value
        tr '\n' ',' |                              # Replace newlines with commas
        sed 's/,$//'                               # Remove trailing comma
        )

        # Alternative method using jq if available (much cleaner)
        if command -v jq >/dev/null 2>&1; then
        languages=$(echo "$response" | jq -r '.spoken_languages[]?.english_name // empty' | tr '\n' ',' | sed 's/,$//')
        fi

        if [[ -n "$languages" ]] && [[ "$languages" != "null" ]]; then
        # Replace commas with comma+space for better readability
        language=$(echo "$languages" | sed 's/,/, /g')
        fi
    fi
    
    # Format rating
    rating=$(printf "%.1f" "$rating" 2>/dev/null || echo "0.0")
    
    # Defaults
    [[ -z "$title" ]] && title="N/A"
    [[ -z "$release_date" ]] && release_date="N/A"
    [[ -z "$year" ]] && year="NA"
    [[ -z "$overview" ]] && overview="N/A"
    [[ -z "$runtime" ]] && runtime="0"
    [[ -z "$genres" ]] && genres="Unknown"
    [[ -z "$cast" ]] && cast="N/A"
    [[ -z "$country" ]] && country="N/A"
    [[ -z "$language" ]] && language="N/A"
    
    # Format runtime as #h #m (FIXED)
    local runtime_formatted="N/A"
    if [[ "$runtime" != "0" ]] && [[ "$runtime" != "N/A" ]] && [[ "$runtime" =~ ^[0-9]+$ ]]; then
        local hours=$((runtime / 60))
        local minutes=$((runtime % 60))
        if [[ $hours -gt 0 ]]; then
            if [[ $minutes -gt 0 ]]; then
                runtime_formatted="${hours}h ${minutes}m"
            else
                runtime_formatted="${hours}h"
            fi
        else
            runtime_formatted="${minutes}m"
        fi
    fi
    
    # Create tag filename
    local tagfile="[TMDB]=-_Score_${rating}_-_${genres}_-_(${year})_-=[TMDB]"
    
    # Create .imdb file content
    local imdb_link="N/A"
    if [[ -n "$imdb_id" ]] && [[ "$imdb_id" != "null" ]] && [[ "$imdb_id" != "N/A" ]]; then
        imdb_link="https://www.imdb.com/title/$imdb_id/"
    fi
    
    local tmdb_link="https://www.themoviedb.org/movie/$movie_id"
    local tmdb_ver="$(grep 'VER=' $GLROOT/bin/tmdb.sh | cut -d'=' -f2)"
    local content=$(cat <<- EOF
	============================ TMDB INFO v$tmdb_ver ================================

	Title........: $title ($year)
	Released.....: $release_date

	IMDB Link....: $imdb_link
	TMDB Link....: $tmdb_link
	Genre........: ${genres//_/, }
	User Rating..: $rating/10

	Country......: $country
	Language.....: $language
	Runtime......: $runtime_formatted

	Cast.........: $cast

	Plot.........: $overview

	============================ TMDB INFO v$tmdb_ver ================================
	EOF
	)
    echo "$tagfile|$content"
}

# Check if BOTH .imdb file AND tag file exist
has_existing_info() {
    local dir="$1"
    
    # Check for .imdb file
    [[ ! -f "$dir/.imdb" ]] && return 1
    
    # Check for at least one IMDB/TMDB tag file
    for file in "$dir"/*; do
        [[ -f "$file" ]] || continue
        filename=$(basename "$file")
        # Check if filename contains IMDB or TMDB (uppercase)
        if [[ "$filename" == *IMDB* ]] || [[ "$filename" == *TMDB* ]]; then
            return 0  # Found both .imdb AND a tag file
        fi
    done
    
    return 1  # Either missing .imdb or missing tag file
}
# Main function
main() {
    echo "${GREEN}=== TMDB Movie Recanner ===${RESET}"
    [[ "$DRY_RUN" == true ]] && echo "${YELLOW}DRY RUN - no files will be created${RESET}"
    [[ "$TIMESTAMP_ONLY" == true ]] && echo "${YELLOW}TIMESTAMP ONLY MODE - only restoring timestamps${RESET}"
    echo
    
    for section in $SECTIONS; do
        local path="$GLROOT$section"
        [[ ! -d "$path" ]] && continue
        
        echo "${GREEN}Scanning: $section${RESET}"
        
        # Get directories in the section
        for dir in "$path"/*/; do
            [[ ! -d "$dir" ]] && continue
            
            # Remove trailing slash if present
		    dir="${dir%/}"
            
            local dir_name=$(basename "$dir")
            
            if [[ "$TIMESTAMP_ONLY" == true ]]; then
                # TIMESTAMP ONLY MODE: Just restore timestamp
                echo "  Check: $dir_name"
                restore_dir_timestamp "$dir"
                continue
            fi
                        
            
            # NORMAL MODE: Skip if already has info
            if has_existing_info "$dir"; then
                echo "  Skip: $dir_name (has info)"
                continue
            fi
            
            # Extract movie info
            local info=$(extract_movie_info "$dir_name")
            local title=$(echo "$info" | cut -d'|' -f1)
            local year=$(echo "$info" | cut -d'|' -f2)
            
            # Skip if no title
            [[ -z "$title" ]] && continue
            
            # Clean title
            title=$(clean_title "$title")
            
            echo "  Search: $title ${year:+($year)}"
            
            # Search TMDB
            local movie_id=$(search_tmdb "$title" "$year")
            
            if [[ -z "$movie_id" ]]; then
                echo "    ${RED}Not found${RESET}"
                continue
            fi
            
			# Get details
			local result=$(get_movie_details "$movie_id")
			
			# Extract tagfile (everything before first |)
			local tagfile="${result%%|*}"
			
			# Extract content (everything after first |)
			local content="${result#*|}"            
            
            echo "    ${GREEN}Found: $(echo "$content" | grep "Title" | cut -d: -f2- | head -1)${RESET}"
            echo "    Tag file: $tagfile"
            
            # Create files
            if [[ "$DRY_RUN" == false ]]; then
                # Look for .rar or .nfo file to use as timestamp reference
                local ref_file=""

                # First try .nfo files
                for f in "$dir"/*.nfo; do
                if [[ -f "$f" ]]; then
                    ref_file="$f"
                    echo "    ${GREEN}Using .nfo file for timestamp reference: $(basename "$f")${RESET}"
                    break
                fi
                done

                # If no .nfo found, try .rar files
                if [[ -z "$ref_file" ]]; then
                for f in "$dir"/*.rar; do
                    if [[ -f "$f" ]]; then
                    ref_file="$f"
                    echo "    ${GREEN}Using .rar file for timestamp reference: $(basename "$f")${RESET}"
                    break
                    fi
                done
                fi

                # Create .imdb file with content
                echo "$content" > "$dir/.imdb"
                echo "    ${GREEN}Created .imdb file${RESET}"

                # Create empty tag file with the name
                printf '' > "$dir/$tagfile"
                echo "    ${GREEN}Created empty tag file: $tagfile${RESET}"

                # Restore directory timestamp using reference file
                if [[ -n "$ref_file" ]]; then
                touch -r "$ref_file" "$dir"
                echo "    ${GREEN}Restored directory timestamp from: $(basename "$ref_file")${RESET}"
                else
                echo "    ${YELLOW}Warning: No .rar or .nfo file found to restore timestamp${RESET}"
                fi
            else
                echo "    ${YELLOW}Would create: .imdb and $tagfile${RESET}"
                echo "    ${YELLOW}Would look for .rar or .nfo file to restore timestamp${RESET}"
            fi
            
            # Be nice to API
            sleep 0.5
        done
    done
    
    echo "${GREEN}=== Done ===${RESET}"
}

main "$@"
