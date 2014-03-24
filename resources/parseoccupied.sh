
# This checks the downloaded rss feed to see if anyone is home.
occupied="$(cat feed.tmp | perl -ne 'print "$2\n" if /<(issued)>(.*)<\/\1>/; print "$2" if /<(title)>(.*)home<\/\1>/;' | tac | awk '{Log[$1]=$2} END{occupied=false; for (person in Log) {if (Log[person]=="arrived") {occupied="true"}} if (occupied == "true"){print "Someone is home"} else {print "No one is home"}}')"