#!/bin/sh
#DynDNS Updatescript für OpenWrt
#Exitcode 0 = WAN-IP-Adresse hat sich nicht geändert oder wurde erfolgreich bei DynDNS erneuert
#Exitcode 1 = WAN-IP-Adresse ist nicht konform
#Exitcode 2 = Datei /var/wanip konnte nicht zurückgesetzt werden
#Exitcode 3 = DynDNS Antwort ist weder "good" noch "nochg" [http://dyn.com/support/developers/api/return-codes/]

#DynDNS Query-String ( http://username:password@members.dyndns.org/nic/update? ... ) [http://dyn.com/support/developers/api/perform-update/]
dyndns="http://xxx:xxx@members.dyndns.org/nic/update?hostname=xxx"

wanip_output="$( ifconfig pppoe-wan | grep 'inet addr:' | awk -F: '{print $2}' | awk '{print $1}' )"
echo $wanip_output | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}$" > "/dev/null"
if [ $? -gt 0 ]
then
	exit 1
	#WAN-IP-Adresse ist nicht konform
fi
if [ -f "/var/wanip" ]
then
	if [ "$wanip_output" = "$( cat "/var/wanip" )" ]
	then
		exit 0
		#WAN-IP-Adresse hat sich nicht geändert
	fi
fi
echo > "/var/wanip"
if [ $? -gt 0 ]
then
	exit 2
	#Datei /var/wanip konnte nicht zurückgesetzt werden
fi
dyndns_output="$( wget --user-agent="Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; WOW64; Trident/6.0)" --quiet --output-document "-" "$dyndns&myip=$wanip_output" )"
echo "$dyndns_output" | grep "good" > "/dev/null"
if [ $? -gt 0 ]
then
	echo "$dyndns_output" | grep "nochg" > "/dev/null"
	if [ $? -gt 0 ]
	then
		exit 3
		#DynDNS Antwort ist weder "good" noch "nochg" [http://dyn.com/support/developers/api/return-codes/]
	fi
fi
echo $wanip_output > "/var/wanip"
exit 0
#WAN-IP-Adresse wurde erfolgreich bei DynDNS erneuert