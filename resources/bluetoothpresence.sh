
# Bluetooth sensing of devices
#sudo ./btPing.sh $MAC1 $MAC2 > presence.tmp # btPing.sh must be in sudoers file

# Now decide if anyone is home...
occupied=$(cat presence.tmp | grep "No one is home" || echo "Someone is home")
echo "Current status at home: "$occupied

# This shows who's home
if [[ "$occupied" == "Someone is home" ]]
then
cat presence.tmp
fi