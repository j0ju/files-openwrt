if ! which tempfile > /dev/null ; then
	tempfile() {
		local dir="/tmp"
		local file="$dir/`(echo $$; head -c 3 /dev/random ; )| md5sum | cut -f1 -d' '`"
		while [ -e "$file" ]; do
			file="$dir/`(echo $$; head -c 3 /dev/random ; )| md5sum | cut -f1 -d' '`"
		done
		echo -n >> "$file"
		chmod 600 "$file"
		echo "$file"
	}
fi
