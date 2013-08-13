sm-c
====

A sendmail replacement/connector. Sendmail-connector (sm-c) connects mailx or cron with msmtp. It requires "msmtp" installed.
If called from cron/cronie, the script scans the /etc/alias file for valid domain email addresses and calls msmtp (http://msmtp.sourceforge.net/).


INSTALLATION
Put the sm-c.sh script anywhere (e.g. /usr/local/bin/) and create a symbolic link:

    ln -s /usr/local/bin/find_email_aliases.sh /usr/bin/sendmail

Please note that sm-c conflicts with mta-msmtp which does nothing but create the "/usr/bin/sendmail" symbolic link to msmtp.
Removing msmtp-mta is recommended, but the msmtp package must remain installed.


ALTERNATIVE INSTALLATION

A PKGBUILD for Arch Linux is now available here.
Dependencies: msmtp
Conflicts:    msmtp-mta, esmtp, ssmtp


HISTORY
- Jim Lofft 06/19/2009, find_alias_for_msmtp.sh
- Changed by Ovidiu Constantin <ovidiu@mybox.ro> && http://blog.mybox.ro/

Reworked heavily by Wiesław Magusiak (wm)/(wiemag)/(dif) and tested with mailx and cron/cronie 
(both calling /usr/bin/sendmail)


SOME ADVICE

1. Do not make cron/cronie call msmtp instead of sendmail; Calling sendmail is default.
2. Create sendmail as a symbolic link to this script, mailx, or msmtp. (Mailx and msmtp are not recommended.)
3. The language/charset settings for cron/cronie are different from those set in the linux system. Put this settings in your user cronjobs file (crontab -e). Here is an example with the Polish language settings.
   -   LANG=pl_PL.UTF-8
   -   LANGUAGE=pl
   -   LC_CTYPE=pl_PL.UTF-8

   If you do not put these into your cronjobs file, you may not be able to send mail if there are any "language" characters in the subject line. This script will help you avoid problems with charset in the contents of your mail even if you do not set your language for cron, but will not help if special characters are in your subject line. The charset is set to utf-8 in the script (see the CS variable). You can change it manually after installation.
4. With this script, you will be able to send e-mail messages with attachments from cron/cronie.
