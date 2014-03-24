# This will grab the rss feed from gmail for the location log
curl -u $username:$password --silent "https://mail.google.com/mail/feed/atom/${presence_filter}" > feed.tmp
# This will print the current status of each person that is here
cat feed.tmp | perl -ne 'print "$2\n" if /<(issued)>(.*)<\/\1>/; print "$2" if /<(title)>(.*)home<\/\1>/;' | tac | awk '{Log[$1]=$2} END{for (person in Log) {print person, Log[person]}}'