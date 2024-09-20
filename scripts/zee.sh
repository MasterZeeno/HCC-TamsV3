#!/usr/bin/env bash
INPUT_FILE="$(find "$PWD/dist" -nowarn -type f -name "*user.js" -print -quit)"
if [ -z "$INPUT_FILE" ];then
echo "No files found in dist folder."
exit 1
fi
OUTPUT_FOLDER="$EXTERNAL_STORAGE/backups/tampermonkey/"
if [ ! -d "$OUTPUT_FOLDER" ];then
mkdir -p "$OUTPUT_FOLDER"||{
echo "Failed to create $OUTPUT_FOLDER"
exit 1
}
fi
cp -f "$INPUT_FILE" "$OUTPUT_FOLDER" 2>&1
MSG="$(basename "$INPUT_FILE")"
if [ $? -eq 0 ];then
echo "Successfully copied $MSG"
else
echo "Failed to copy $MSG"
fi
