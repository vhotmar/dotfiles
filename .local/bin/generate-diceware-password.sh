#!/bin/bash

temp_location="/tmp"
file_name="eff_short_wordlist_2_0.txt"
file_path="${temp_location}/${file_name}"
url="https://www.eff.org/files/2016/09/08/eff_short_wordlist_2_0.txt"
expected_checksum="79a46e82a7e8d23f777aa39283b48ab29534602e"

# Check if the file exists
if [ ! -f "${file_path}" ]; then
	curl -o "${file_path}" "${url}"
fi

# Validate checksum
checksum=$(shasum "${file_path}" | awk '{print $1}')
if [ "${checksum}" != "${expected_checksum}" ]; then
	echo "Checksum validation failed."
	exit 1
fi

# Check if argument is provided
if [ $# -ne 1 ]; then
	echo "Usage: $0 <number_of_words>"
	exit 1
fi

number_of_words=$1
result=""
short_result=""

for ((i = 0; i < number_of_words; i++)); do
	search_number=$(jot -r 4 1 6 | tr -d '\n')
	word=$(grep "^${search_number}" "${file_path}" | cut -f 2)

	if [ -z "${result}" ]; then
		result="${word}"
		short_result="${word:0:3}"
	else
		result="${result}-${word}"
		short_result="${short_result}${word:0:3}"
	fi
done

# Print the word list
echo "${result}"
# Print the short word list
echo "${short_result}"
