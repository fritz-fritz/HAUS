
# Now lets log what the current state of the switch is:
echo "The WeMo switch is "$current_condition
# If this is first run then set "set_condition" to current wemo state (workaround)
if [[ "$set_condition" == "" ]]
then
set_condition="$current_condition"
else
echo "The switch is scheduled to be "$set_condition
fi
