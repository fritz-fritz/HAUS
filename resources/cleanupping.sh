

################## Cleanup ##################
# Now we wrap up, sleep to reduce cpu load on both ends, and loop
previous_condition=$occupied
rm switch.tmp
echo "" # formatting to keep log readable
sleep $sleeptime
done