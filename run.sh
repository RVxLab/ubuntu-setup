#!/bin/bash

set -e

function copyFile {
    local SOURCE=$1
    local DESTINATION=$2

    if [[ -f "$DESTINATION" ]]
    then
        cp "$DESTINATION" "$DESTINATION.bak"
        echo "Backed up $DESTINATION to $DESTINATION.bak"
    fi

    cp "$SOURCE" "$DESTINATION"
}

PWD=$(dirname "$0")
DESTINATION_DIR="$HOME"
FILES_DIR="$PWD/files"

while IFS= read -r -d '' FILE
do
    FILE_TO_COPY=$(sed "s@$PWD/files/@@" <<< "$FILE")
    DESTINATION_FILE="$DESTINATION_DIR/$FILE_TO_COPY"

    copyFile "$FILE" "$DESTINATION_FILE"
    echo "Copied $FILE to $DESTINATION_FILE"
done < <(find "$FILES_DIR" -type f -print0)
