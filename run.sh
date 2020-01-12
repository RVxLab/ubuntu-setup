#!/bin/bash

function prompt {
    local QUESTION=$1

    while true
    do
        printf "$QUESTION > [N/y]: "
        read CONFIRM

        if [[ $CONFIRM == "y" || $CONFIRM == "Y" ]]
        then
            return 0
        elif [[ $CONFIRM == "n" || $CONFIRM == "N" || -z $CONFIRM ]]
        then
            return 1
        fi
    done
}

function copyFile {
    local SOURCE=$1
    local DESTINATION=$2

    cp "$SOURCE" "$DESTINATION"
}

FORCE=0

while getopts "f" OPT
do
    case "$OPT" in
        f)
            FORCE=1
            ;;
    esac
done

DESTINATION_DIR="$HOME"

for FILE in $(find files -type f)
do
    CUT_FILE="$(echo $FILE | cut -b 7-)"
    DESTINATION_FILE="$DESTINATION_DIR/$CUT_FILE"

    if [[ ! -f $DESTINATION_FILE ]]
    then
        echo "Creating $CUT_FILE"
        copyFile "$FILE" "$DESTINATION_FILE"
    else
        if [[ $FORCE -eq 1 ]]
        then
            echo "Overwriting $CUT_FILE"
            copyFile "$FILE" "$DESTINATION_FILE"
        elif prompt "$CUT_FILE already exists in $DESTINATION_DIR, overwrite?"
        then
            echo "Overwriting $CUT_FILE"
            copyFile "$FILE" "$DESTINATION_FILE"
        else
            echo "Skipping $CUT_FILE"
        fi
    fi
done
