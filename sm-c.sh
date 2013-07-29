#!/bin/bash
# sm-c.sh by Wiesław Magusiak (2013-07-15)
# A "sendmail" replacement. Requires "msmtp" installed.
# Put this script anywhere (e.g. /usr/local/bin/) and create a symbolic link:
# 
# 	# ln -s /usr/local/bin/find_email_aliases.sh /usr/bin/sendmail
#
# If called from cron/cronie, the script scans the /etc/alias file for valid domain
# email addresses and calls msmtp (http://msmtp.sourceforge.net/).
#
# History:
# Jim Lofft 06/19/2009, find_alias_for_msmtp.sh
# Changed by Ovidiu Constantin <ovidiu@mybox.ro> && http://blog.mybox.ro/
# Reworked heavily by Wiesław Magusiak <w.magusiak@gmail.com>
# and tested with mailx and cron/cronie (both calling /usr/bin/sendmail, a symlink to msmtp)
#
# Some advice:
# (1) Do not make cron/cronie call msmtp instead of sendmail; Calling sendmail is default.
# (2) Do nor make mailx call msmtp. By default it will call sendmail.
# (3) Create sendmail as a symbolic link to this script.
# (4) The language/charset settings for cron/cronie are different from those 
#     set in the linux system. Put these settings in your user cronjobs file (crontab -e).
#     Here is an example with the Polish language settings.
#       LANG=pl_PL.UTF-8
#       LANGUAGE=pl
#       LC_CTYPE=pl_PL.UTF-8
#     If you do not put these into your cronjobs file, you will not be able to send
#     mail if there are any "language" characters in the subject line. This script
#     will help you avoid problems with charset in the contents of your mail even if
#     you do not set your language for cron, but will not help if special characters
#     are in your subject line.
#     Remember to set the charset below.
# (4) With this script, you will be able to send e-mail messages with attachments
#     from cron/cronie.
# ---------------------------------------------------------------------------------- #
# This is a fully functional script stuffed with a lot of lines for debugging.       #
# Check "$DEBUG" after mailx has been called directly or cron sent an email message.  #
# You can safely remove all "debugging parts" from the script below.                 #
# ---------------------------------------------------------------------------------- #

DEBUG="/dev/null"
if [[ -f ~/.sm-c.conf ]]; then
	D=$(grep ^debug ~/.sm-c.conf|cut -d= -f2)		# set debug={1, y, Y, yes, Yes, yEs,...}
elif [[ -f /etc/sm-c.conf ]]; then
	D=$(grep ^debug /etc/sm-c.conf|cut -d= -f2)		# set debug={1, y, Y, yes, Yes, yEs,...}
fi

[[ "$D" == "1" || "$D" == "[Yy]" || "$D" == "[yY][eE][sS]" ]] && DEBUG=/tmp/sm-${USER}.log
	
PARAMS="$@"			# Parameters sendmail is called with
TO=0				# E-mail address(es)
MSG="$(cat)"		# Message contents passed to sendmail
CS="charset=utf-8"	# Charset for email. 
					# Needs to be set when mailx is called by cron/cronie.
MSMTP="$(which msmtp)"

# ---- Debugging part ------------------
if [ -n "$DEBUG" ]; then
	echo -e "The sendmail call from a program:\n\t$0 $@" > "$DEBUG"
	echo "-------------------" >> "$DEBUG"
	echo -n "Called from " >> "$DEBUG"
	[[ -t 1 ]] && echo "a terminal" >> "$DEBUG" || echo "not-a-terminal" >> "$DEBUG"
	#[[ -t 1 || -t 0 ]] && echo "a terminal" >> "$DEBUG" || echo "not a terminal" >> "$DEBUG"
	echo "-------------------" >> "$DEBUG"
fi
# ---- End of debugging part -----------

# mailx calls sendmail with -i as the first parameter and addresses as the following parameters
if [  "$1" = '-i'  ]; then
	# No shift of parameters to include the "-i" flag in $TO
	#shift
	TO="$@"
	# If mailx is called from cron and no language settings are put into user's cronjobs file,
    # the "Content-Type" part of an email header has to be changed
	# from  Content-Type: application/octet-stream
	#   to  Content-Type: text/plain; charset=utf-8
	# Without it, thunderbird will not show your message "inline".
	MSG="${MSG/Type: application\/octet-stream/Type: text\/plain; $CS}"
	# ---- Debugging part ------------------
	if [ -n "$DEBUG" ]; then
        	# Check how option -t (below) works if $MSG contains a "To: " line.
		kk="$(echo "$MSG" | grep -m 1 'To: ')"
        kk="${kk:4}"
		if [[ -n "$kk" ]]; then
			echo -e "Check how option -t works. This should be the adress line:\n$kk"  >> "$DEBUG"
			echo "-------------------" >> "$DEBUG"
		fi
	fi
	# ---- End of debugging part -----------

# crone/cronie calls sendmail with -FConeDaemon as the first parameter
# 	(-FCronDaemon -i -odi -oem -oi -t -f <user>)
elif [ "$1" = '-FCronDaemon' ]; then
	RECIP="$(echo "${@:$#}")"
	# ---- Debugging part ------------------
	if [ -n "$DEBUG" ]; then
		echo "\$RECIP=$RECIP"  >> "$DEBUG"
	fi
	# ---- End of debugging part -----------
	if [ -f /etc/aliases ]; then
		#-----Find email addresses and remove commas between them if any.
		TO="$(grep "$RECIP:" /etc/aliases|cut -d: -f2|sed "s/\, / /g"|sed "s/ *$//g")"
		TO="-i$TO"	# $TO starts with a space here.
            #-----Unnecessary or even wrong, but satisfies my aesthetic taste (in thunderbird)----------
			TO1="$(echo "$TO"|cut -d\  -f2)"        # To have just one sender/adressee displayed
			MSG="${MSG/To: $RECIP/To: $TO1}"		# Replace "To: $RECIP" with "To: $TO"
			MSG="${MSG/From: $RECIP/From: $TO1}"	# Replace "From: $RECIP" with "From: $TO"
            #-----The end of "Unnecessary or even wrong"------------------------------------------------
		#-----An option; a full parameters line
        # (It does not work quite well, sending email to one addressee from cron, not all of them.)
		# TO=${PARAMS/-f $RECIP/-f $TO}
	else
		echo "Missing file:  /etc/aliases."
		exit 1
		#-----An alternative solution----
		# DEFAULTEMAIL="a_VIP@domain.com"
		# TO="-i "$DEFAULTEMAIL
	fi
	# ---- Debugging part ------------------
		#echo \$RECIP=$RECIP  >> "$DEBUG"
	# ---- End of debugging part -----------

# other programs
elif [ "$1" = '-t' ]; then  # most other programs (which?) call sendmail with a -t option
	TO="$(echo "$MSG" | grep -m 1 'To: ')"
	TO="-i ${TO:4}"
else
	TO="$PARAMS" 	# Just the original parameter(s) sendmail was called with.
fi

# ---- Debugging part ------------------
if [ -n "$DEBUG" ]; then
	echo "The arguments for msmtp: $TO" >> "$DEBUG"
	echo -------e-mail_structure------- >> "$DEBUG"
	echo -e "$MSG" >> "$DEBUG"
	echo -------end_of_email----------- >> "$DEBUG"
fi
# ---- End of debugging part -----------

echo -e "$MSG" | "$MSMTP" $TO
