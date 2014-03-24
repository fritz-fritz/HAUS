# This will grab the rss feed from gmail for the WeMo status
curl -u $username:$password --silent "https://mail.google.com/mail/feed/atom/${wemo_filter}" > switch.tmp
current_condition="$(cat switch.tmp | perl -ne 'print "$2\n" if /<(title)>(.*)<\/\1>/; print "$2" if /<(title)>(.*):<\/\1>/;' | awk 'BEGIN{FS=":|switched "}; {if (NR==2) {print $2}}')"