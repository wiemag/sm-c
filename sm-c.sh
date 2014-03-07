#!/bin/bash
# sm-c.sh v1.1 by Wiesław Magusiak (2013-07-31)
# sm-c.sh v1.4 (2014-03-07)
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
# (2) Do not make mailx call msmtp. By default it will call sendmail.
# (3) If you install this script with its package, it will check dependecies and conflicts,
#     and will create sendmail as a symbolic link to this script.
#     Otherwise, put the script somewhere (e.g. /usr/local/bin/) and create the symbolic
#     manually.
# (4) The language/charset settings for cron/cronie are different from those
#     set in the linux system. Put these settings in your user cronjobs file (crontab -e).
#     Here is an example with Polish language settings.
#       LANG=pl_PL.UTF-8
#       LANGUAGE=pl
#       LC_CTYPE=pl_PL.UTF-8
#     Failing to do that may lead to your not being able to send e-mail.
#     It is an error in system, not in sm-c.
# (5) With this script and mailx, you will be able to send e-mail messages with attachments
#     from cron/cronie.
# ---------------------------------------------------------------------------------- #
# This is a fully functional script stuffed with a lot of lines for debugging.       #
# Check "$DEBUG" after mailx has been called directly or cron sent an email message. #
# You can safely remove all "debugging parts" from the script below.                 #
# ---------------------------------------------------------------------------------- #

PARAMS=" $@ "		# Parameters sendmail is called with
TO=0				# E-mail address(es)
MSG="$(cat)"		# Message contents passed to sendmail
CS="charset=utf-8"	# Charset for email.
					# Needs to be set when mailx is called by cron/cronie.
U=$USER 			# If sendmail is called from cron, U=""

PREFIX=${PARAMS% -*}
	echo PARAMS=:$PARAMS:
	echo PREFIX=:$PREFIX:
if [[ "$PARAMS" = "$PREFIX" ]]; then
	PREFIX=""
	RECIP="$PARAMS"
	echo równe
else
	echo nierówne
	RECIP=${PARAMS#$PREFIX }
	echo recip=$RECIP
	RECIP=${RECIP#-* }
	echo recip=$RECIP
	PREFIX=${PARAMS% $RECIP}
fi
	echo PARAMS=$PARAMS
	echo PREFIX=$PREFIX
z=""
if [[ -f /etc/aliases ]]; then  	# Does the file exist?
	if [[ -n "$RECIP" ]]; then
		# Make sure recipient addresses are "@domain" style ones
		for x in $RECIP; do 		# Important! No quotation marks here!
			if [[ $x = *@* ]]; then
				z=$z" $x"
			else
				y="$(grep "$x:" /etc/aliases|cut -d: -f2|sed 's/\, / /g'|sed 's/ *$//g')"
				# Recepient without "@domain" who is not listed in /etc/aliases gets eliminated.
				z=$z"$y"
			fi
		done 						# z has a leading space
	fi
else
		for x in $RECIP; do 		# Important! No quotation marks here!
			if [[ $x = *@* ]]; then
				z=$z" $x"
			else
				# Recepient without "@domain" who is not listed in /etc/aliases gets eliminated.
				: 					# continue
			fi
		done 						# z has a leading space
fi
PARAMS="${PREFIX# }${z}" 			# PREFIX holds options; z holds addresses (may be empty, too)
echo PREFIX=${PREFIX# }
echo Adresy=${z}

if [[ -f ~/.sm-c.conf ]]; then
	D=$(grep ^debug ~/.sm-c.conf|cut -d= -f2)		# set debug={1, y, Y, yes, Yes, yEs,...}
elif [[ -f /etc/sm-c.conf ]]; then
	D=$(grep ^debug /etc/sm-c.conf|cut -d= -f2)		# set debug={1, y, Y, yes, Yes, yEs,...}
fi

[[ "$D" == "1" || "$D" == "[Yy]" || "$D" == "[yY][eE][sS]" ]] \
	&& DEBUG=/tmp/sm-${U}-$(date +%H%M%S).log || DEBUG="/dev/null"

SMTPF="$(which msmtp)"

# ---- Debugging part ------------------
if [ -n "$DEBUG" ]; then
	#echo -e "The sendmail call by $(ps -p $(ps -p $$ -o ppid=) -o comm=):\n\t$0 $@" > "$DEBUG"
	echo -e "$(LANG=C date)\nThe sendmail call:\n\t$0 $@" > "$DEBUG"
	echo -n "called from " >> "$DEBUG"
	[[ -t 1 ]] && echo -e "a terminal." >> "$DEBUG" || echo "not a terminal" >> "$DEBUG"
	#[[ -t 1 || -t 0 ]] && echo "a terminal" >> "$DEBUG" || echo "not a terminal" >> "$DEBUG"
	echo "-------------------" >> "$DEBUG"
	echo -e "USER=${U} \tLANG=$LANG" >> "$DEBUG"
	echo -e "PID  \$\$    = $$\t$(ps -p $$ -o comm=)" >> "$DEBUG"
	echo -e "PPID \$PPID = $PPID\t$(ps -p $PPID -o comm=)" >> "$DEBUG"
	#cat /proc/$$/status | grep PPid: | grep -o "[0-9]*" >> "$DEBUG"
	#cat /proc/$$/status | grep Pid: | grep -o "[0-9]*" >> "$DEBUG"
	echo "-------------------" >> "$DEBUG"
fi
# ---- End of debugging part -----------

# mailx calls sendmail with -i as the first parameter and addresses as the following parameters
# Warning: mailx sorts parameters moving those with hyphens before those without hyphens!
# Advice: If you pass parameters with -O, put no spaces between -O and the past paarameters/valuses.
# 
if [  "$1" = '-i'  ]; then 		# Strong assumption: Called by mailx
	# No shift of parameters to include the "-i" flag in $TO
	#shift
	TO="$PARAMS"
	# If mailx is called from cron and no language settings are put into user's cronjobs file,
    # the "Content-Type" part of an email header has to be changed
	# from  Content-Type: application/octet-stream
	#   to  Content-Type: text/plain; charset=utf-8
	# Without it, thunderbird will not show your message "inline".
	MSG="${MSG/Type: application\/octet-stream/Type: text\/plain; $CS}"
	# ---- Debugging part ------------------
	if [ -n "$DEBUG" ]; then
        # Addressee as specified in $MSG, in the "To: " line.
		kk="$(echo "$MSG" | grep -m 1 'To: ')"
        kk="${kk:4}"
		if [[ -n "$kk" ]]; then
			echo -e "Addressee as in the email-header lines:\n$kk"  >> "$DEBUG"
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
            #-----Unnecessary, but satisfies my aesthetic taste (in thunderbird)------------------------
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
elif [ "$1" = '-t' ]; then  	# This and the next "else" could be combined, but
	if [ -n "$DEBUG" ]; then 	# I want them separate at least for debugging reasons
		echo "Mail sent with the -t parameter" >> "$DEBUG"
		echo "-------------------" >> "$DEBUG"
	fi
	TO="$PARAMS" 		# -t draws addresses from $MSG automatically
else
	if [ -n "$DEBUG" ]; then
		echo "* Mail sent without parameters or not recognised ones." >> "$DEBUG"
		echo "* Most likely the message will be prepared but NOT SENT." >> "$DEBUG"
		echo "* Expect an error message like 'No recepients found'" >> "$DEBUG"
		echo "-------------------" >> "$DEBUG"
	fi
	TO="$PARAMS" 	# Just the original parameter(s) sendmail was called with.
fi

# ---- Debugging part ------------------
if [ -n "$DEBUG" ]; then
	echo "The arguments for ${SMTPF##*/}: $TO" >> "$DEBUG"
	echo -------e-mail_structure------- >> "$DEBUG"
	echo -e "$MSG" >> "$DEBUG"
	echo -------end_of_email----------- >> "$DEBUG"
fi
# ---- End of debugging part -----------

echo -e "$MSG" | "$SMTPF" $TO
