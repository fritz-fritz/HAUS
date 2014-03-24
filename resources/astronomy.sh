

################## Get Time & Solar Position ##################
# Let's get the current time
curHour=$(date '+%H')
curMin=$(date '+%M')
curDate=$(date '+%d')

if [[ 10#$curDate != 10#$previous_date && 10#$curHour > 1 ]]
then
# It's a new day!
previous_date=$curDate

# Let's grab sunrise and sunset
curl -s http://weather.yahooapis.com/forecastrss?w=$l|grep astronomy > astronomy.tmp

# Set sunrise time
riseHour=$(cat astronomy.tmp | awk -F\" '{print $2;}' | awk 'BEGIN{FS=":| "};{print $1};')
riseMin=$(cat astronomy.tmp | awk -F\" '{print $2;}' | awk 'BEGIN{FS=":| "};{print $2};')
#	Just in case something is seriously weird
if [[ $(cat astronomy.tmp | awk -F\" '{print $2;}' | awk 'BEGIN{FS=":| "};{print $3};') == "pm" ]]
then
let "setHour += 12"
fi

# Set sunset time
setHour=$(cat astronomy.tmp | awk -F\" '{print $4;}' | awk 'BEGIN{FS=":| "};{print $1};')
setMin=$(cat astronomy.tmp | awk -F\" '{print $4;}' | awk 'BEGIN{FS=":| "};{print $2};')
#	As it should normally be...
if [[ $(cat astronomy.tmp | awk -F\" '{print $4;}' | awk 'BEGIN{FS=":| "};{print $3};') == "pm" ]]
then
let "setHour += 12"
fi

# Let's announce to the log file
echo "It's a new day!"
date
echo "Today's Sunrise: "$riseHour":"$riseMin
echo "Today's Sunset: "$setHour":"$setMin

# Now clean up
rm astronomy.tmp
fi
