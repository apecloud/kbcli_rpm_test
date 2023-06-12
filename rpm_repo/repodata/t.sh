#!/bin/bash
current_dir=$(pwd)
pwd
ls
for file in "$current_dir"/*
do
    if [ -f "$file" ]; then
      filename=$(basename "$file")
      echo "$filename"
      echo "https://api.github.com/repos/apecloud/kbcli_rpm_test/contents/rpm_repo/repodata/$filename"

      curl -X PUT -H "Authorization: token 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" -H "Content-Type: application/json" -d '{"message": "Upload file", "content": "'$(base64 < ./$filename)'"}' "https://api.github.com/repos/apecloud/kbcli_rpm_test/contents/rpm_repo/repodata/$filename"
    fi
done
