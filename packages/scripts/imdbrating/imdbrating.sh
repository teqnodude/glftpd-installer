VER=1.0
#--[ Info ]-----------------------------------------------------#
#
# A script that create an index of a section of movies of the 
# IMDB tag created by psxc-imdb that enables you to filter movies 
# by genre, imdb score and year with a random option.
#
#--[ Settings ]-------------------------------------------------#

glroot=/glftpd
tmp=$glroot/tmp

#--[ Script Start ]---------------------------------------------#

if [ -z "$1" ]
then
    echo "./imdbrating.sh index - to create an index file for a section"
    echo "./imdbrating.sh sort less 4 - to filter out the movies based on score less than 4"
    echo "./imdbrating.sh sort less 4 year 2008 - to filter out the movies based on score greater than 4 for the year 2008"
    echo "./imdbrating.sh sort less 4 genre Action - to filter out the movies based on score greater than 4 for the genre Action"
    echo "./imdbrating.sh sort less 4 random 5 - to filter out the movies based on score less than 4 and take only 5 random results"
    echo "./imdbrating.sh sort greater 4 - to filter out the movies based on score greater than 4"
    echo "./imdbrating.sh sort greater 4 year 2008 - to filter out the movies based on score greater than 4 for the year 2008"
    echo "./imdbrating.sh sort greater 4 genre Action - to filter out the movies based on score greater than 4 for the genre Action"
    echo "./imdbrating.sh sort greater 4 random 5 - to filter out the movies based on score less than 4 and take only 5 random results"
    echo "./imdbrating.sh sort genre Action - to filter out the movies for the genre Action"
fi

if [ "$1" = "index" ]
then
    > $glroot/tmp/imdbrating.txt
    echo -n "Enter section ie X264-1080 : " ; read section
    echo -n "Creating index, please wait...."
    for dir in `ls $glroot/site/$section`
    do
        rating="`ls $glroot/site/$section/$dir | grep -o "Score_.*" | cut -d "_" -f2`"
        year="`ls $glroot/site/$section/$dir | grep -o "(.*)" | grep -v COMPLETE | grep -o "[0-9][0-9][0-9][0-9]"`"
        genre="`ls $glroot/site/$section/$dir | grep -o "Score_.*" | cut -d "_" -f4`"
        if [ ! -z "$rating" ]
        then
            echo "$rating $year $genre $section/$dir" >> $tmp/imdbrating.txt
        fi
    done
    sed -i 's|//|/|g' $tmp/imdbrating.txt
    echo "Done"
fi

if [ "$1" = "sort" ]
then
    if [ ! -e $glroot/tmp/imdbrating.txt ]
    then
        echo "You need to create an index file"
        exit 0
    fi
    if [ "$2" = "less" ]
    then
        if [ "$4" = "year" ]
        then
            awk ' $1<='$3 $tmp/imdbrating.txt | sort -n | grep -i "$5"
        elif [ "$4" = "genre" ]
        then
            awk ' $1<='$3 $tmp/imdbrating.txt | sort -n | grep -i "$5"
        elif [ "$4" = "random" ]
        then
            awk ' $1<='$3 $tmp/imdbrating.txt | sort -n | shuf -n $5
        else
            awk ' $1<='$3 $tmp/imdbrating.txt | sort -n
        fi
    fi
    if [ "$2" = "greater" ]
    then
        if [ "$4" = "year" ]
        then
            awk ' $1>='$3 $tmp/imdbrating.txt | sort -n | grep -i "$5"
        elif [ "$4" = "genre" ]
        then
            awk ' $1>='$3 $tmp/imdbrating.txt | sort -n | grep -i "$5"
        elif [ "$4" = "random" ]
        then
            awk ' $1>='$3 $tmp/imdbrating.txt | sort -n | shuf -n $5
        else
            awk ' $1>='$3 $tmp/imdbrating.txt | sort -n
        fi
    fi
    if [ "$2" = "genre" ]
    then
        cat $tmp/imdbrating.txt | grep -i "$3"
    fi
fi

exit 0
