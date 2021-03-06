

################## Control the Switch ##################
# Now that we know if anyone is home let's do something with that...
# These 'if' statements are designed so we don't keep sending emails...
if [[ "$occupied" == "No one is home" ]]
then
set_condition="off"
if [[ "$current_condition" != "off" ]] && [[ "$previous_condition" != "$occupied" ]]
then
# No one is home. Make sure the light is off. (last test to allow manual override)
wemo switch "$wemo_switch" off
echo "Turning switch "$wemo_switch" off."
fi
fi

if [[ "$occupied" == "Someone is home" ]]
then
if [[ "$current_condition" != "$set_condition" ]] && ( [[ "$previous_condition" != "" ]] || [[ "$previous_condition" == "$current_condition" ]] )
then
override=true
else
override=false
fi

if [[ "$current_condition" != "on" ]] && [[ $override == false ]] && (( $((10#$curHour*60+10#$curMin)) > $((10#$setHour*60+10#$setMin-10#$buffer)) || $((10#$curHour*60+10#$curMin)) < $((10#$riseHour*60+10#$riseMin+10#$buffer)) ))
then
# It's night time and we're home. Turn the light on!
set_condition="on"
wemo switch "$wemo_switch" on
echo "Turning switch "$wemo_switch" on."
elif [[ "$current_condition" != "off" ]] && [[ $override == false ]] && (( $((10#$curHour*60+10#$curMin)) < $((10#$setHour*60+10#$setMin-10#$buffer)) )) && (( $((10#$curHour*60+10#$curMin)) > $((10#$riseHour*60+10#$riseMin+10#$buffer)) ))
then
# It's day time let's make sure the light is off
set_condition="off"
wemo switch "$wemo_switch" off
echo "Turning switch "$wemo_switch" off."
elif [[ "$current_condition" == "off" ]] && (( $((10#$curHour*60+10#$curMin)) < $((10#$setHour*60+10#$setMin-10#$buffer)) && $((10#$curHour*60+10#$curMin)) > $((10#$riseHour*60+10#$riseMin+10#$buffer)) ))
then
# This is to reset override if the light is manually turned off at night
set_condition="off"
fi
fi
