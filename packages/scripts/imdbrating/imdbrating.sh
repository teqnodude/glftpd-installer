VER=1.1
#--[ Info ]----------------------------------------------------
#
# A script that create an index of a section of movies of the 
# IMDB tag created by psxc-imdb that enables you to filter movies 
# by genre, imdb score and year with a random option.
#
#--[ Settings ]------------------------------------------------

glroot="/glftpd"
tmp="$glroot/tmp"

#--[ Script Start ]--------------------------------------------

if [[ -z "$1" ]]
then

	cat <<-EOF
		$0 index - to create an index file for a section
		$0 sort less 4 - to filter out the movies based on score less than 4
		$0 sort less 4 year 2008 - to filter out the movies based on score less than 4 for the year 2008
		$0 sort less 4 genre Action - to filter out the movies based on score less than 4 for the genre Action
		$0 sort less 4 random 5 - to filter out the movies based on score less than 4 and take only 5 random results
		$0 sort greater 4 - to filter out the movies based on score greater than 4
		$0 sort greater 4 year 2008 - to filter out the movies based on score greater than 4 for the year 2008
		$0 sort greater 4 genre Action - to filter out the movies based on score greater than 4 for the genre Action
		$0 sort greater 4 random 5 - to filter out the movies based on score greater than 4 and take only 5 random results
		$0 sort genre Action - to filter out the movies for the genre Action
	EOF

fi



if [[ "$1" == "index" ]]
then

    mkdir -p "$tmp"
    : > "$tmp/imdbrating.txt"

    printf "Enter section (e.g. X264-1080): "
    read -r section

    printf "Creating index, please wait...."

    # iterate section subdirs robustly (handles spaces/newlines)
    shopt -s nullglob
    for dir in "$glroot/site/$section"/* 
    do

        [[ -d "$dir" ]] || continue

        # consider any file in dir that contains "IMDB"
        for f in "$dir"/*IMDB* 
        do

            [[ -e "$f" ]] || continue

            fname="${f##*/}"

            # rating: Score_(NA|digit[.digit])
            rating="$(sed -nE 's/.*Score_((NA|[0-9](\.[0-9])?)).*/\1/p' <<< "$fname")"

            # year: first 4 consecutive digits
            year="$(sed -nE 's/.*([0-9]{4}).*/\1/p' <<< "$fname")"

            # genre: strip parentheses tail; drop leading "Score_*_-_"
            genre="$(sed -E 's/\(.*$//; s/.*Score_(NA|[0-9](\.[0-9])?)_-_//' <<< "$fname")"

            if [[ -n "$rating" ]]
            then

                printf '%s %s %s %s/%s\n' \
                    "$rating" "$year" "$genre" "$section" "${dir##*/}" >> "$tmp/imdbrating.txt"

            fi

        done

    done
    shopt -u nullglob

    # normalize accidental double slashes (defensive)
    sed -i 's|//|/|g' "$tmp/imdbrating.txt"

    echo "Done"

fi


if [[ "$1" == "sort" ]]
then

    if [[ ! -e "$glroot/tmp/imdbrating.txt" ]]
    then

        echo "You need to create an index file"
        exit 1

    fi

    if [[ "$2" == "less" ]]
    then

        if [[ "$4" == "year" ]]
        then

            awk '$1 <= '"$3" "$tmp/imdbrating.txt" | sort -n | grep -i "$5"

        elif [[ "$4" == "genre" ]]
        then

            awk '$1 <= '"$3" "$tmp/imdbrating.txt" | sort -n | grep -i "$5"

        elif [[ "$4" == "random" ]]
        then

            awk '$1 <= '"$3" "$tmp/imdbrating.txt" | sort -n | shuf -n "$5"

        else

            awk '$1 <= '"$3" "$tmp/imdbrating.txt" | sort -n

        fi

    fi

    if [[ "$2" == "greater" ]]
    then

        if [[ "$4" == "year" ]]
        then

            awk '$1 >= '"$3" "$tmp/imdbrating.txt" | sort -n | grep -i "$5"

        elif [[ "$4" == "genre" ]]
        then

            awk '$1 >= '"$3" "$tmp/imdbrating.txt" | sort -n | grep -i "$5"

        elif [[ "$4" == "random" ]]
        then

            awk '$1 >= '"$3" "$tmp/imdbrating.txt" | sort -n | shuf -n "$5"

        else

            awk '$1 >= '"$3" "$tmp/imdbrating.txt" | sort -n

        fi

    fi

    if [[ "$2" == "genre" ]]
    then

        grep -i "$3" "$tmp/imdbrating.txt"

    fi

fi
