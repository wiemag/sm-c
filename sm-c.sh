#!/bin/bash
# sm-c.sh by Wiesław Magusiak (2013-07-15)
# A "sendmail" replacement. Requires "msmtp" installed.
# Put this script anywhere (e.g. /usr/local/bin/) and create a symbolic link:
#
# 	# ln -s /usr/local/bin/find_email_aliases.sh /usr/bin/sendmail
#
# If called from cron/cronie, the script scans the /etc/alias file for valid domain
# email addresses and calls msmtp (http://msmtp.sourceforge.net/).
# ------------------------------------------------------------------------------------------

PARAMS=$@		# Parameters sendmail is called with
TO=0			# E-mail address(es)
MSG=$(cat)		# Message contents passed to sendmail
CS="charset=utf-8"	# Charset for email. 
			# Needs to be set when mailx is called by cron/cronie.
MSMTP=$(which msmtp)

# mailx calls sendmail with -i as the first parameter and addresses as the following parameters
if [  "$1" = '-i'  ]; then
	TO=$@
	MSG=${MSG/Type: application\/octet-stream/Type: text\/plain; $CS}

# crone/cronie calls sendmail with -FConeDaemon as the first parameter
elif [ "$1" = '-FCronDaemon' ]; then
	RECIP=$(echo ${@:$#})
	if [ -f /etc/aliases ]; then
		#-----Find email addresses and remove commas between them if any.
		TO=$(grep $RECIP: /etc/aliases|cut -d: -f2|sed "s/\, / /g"|sed "s/ *$//g")
		TO="-i"$TO	# $TO starts with a space here.
            #-----Unnecessary or even wrong, but satisfies my aesthetic taste (in thunderbird)--
			TO1=$(echo $TO|cut -d\  -f2)        # To have just one sender/adressee displayed
			MSG=${MSG/To: $RECIP/To: $TO1}		# Replace "To: $RECIP" with "To: $TO"
			MSG=${MSG/From: $RECIP/From: $TO1}	# Replace "From: $RECIP" with "From: $TO"
            #-----The end of "Unnecessary or even wrong"----------------------------------------
	else
		echo "Missing file:  /etc/aliases."
		exit 1
	fi

# other programs
elif [ "$1" = '-t' ]; then  # most other programs (which?) call sendmail with a -t option
	TO=$(echo "$MSG" | grep -m 1 'To: ')
	TO="-i "${TO:4}
else
	TO=$PARAMS 	# Just the original parameter(s) sendmail was called with.
fi

echo -e "$MSG" | $MSMTP $TO
