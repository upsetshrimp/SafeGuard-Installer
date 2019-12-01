#! /usr/bin/expect
#To be launcehd via gnome-terminal in ~.profile
#Gains root access and launches second iteration of SafeGuard installer
#Prerequisit: user's password has to be set as "user1!"

# Very Important TODO, add if statement, if the password is incorrect, it prompts the user to enter it and then runs the second iteration..

spawn sudo -i
expect "*:"
send "user1!\n"
expect "*#"
send "bash /opt/SecondIteration.sh\r"
interact