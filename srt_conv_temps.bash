#!/bin/bash
# janvd.free.fr
# version 3.11

Debug=0

[[ $Debug > 0 ]] && printf "[Debug(1)] Demarrage\n" >&2

# test des arguments en entrée

if [[ $1 == "" ]]
then
	printf "Erreur - Usage : $0 chaine_a_convertir(HH:MM:SS,mmm) ou en_milli\n"
	exit 2
else
		chaine=$1

		[[ $Debug > 1 ]] && printf "[Debug(2)] chaine = $chaine\n" >&2
fi

# fonction qui converti une chaine en milli ; usage : srt_conv_temps chaine

function srt_conv_chaine2milli
{
	f_chaine=$1

	[[ $Debug > 1 ]] && printf "[Debug(2) (function srt_conv_chaine2milli)  f_chaine = $f_chaine\n" >&2

	echo $chaine | awk -F":|," '{ t=($1*60*60*1000 + $2*60*1000 + $3*1000 + $4) ; print t }'
}

# fonction qui converti le temps de milliseconde en hh:mm:ss,milli ; usage : srt_conv_temps temps_milli

function srt_conv_milli2chaine
{
	f_temps=$1

	[[ $Debug > 1 ]] && printf "[Debug(2) (function srt_conv_milli2chaine)  f_option = $f_temps\n" >&2

	echo $f_temps | awk '{ milli=$1 ; hh=(milli/(60*60*1000)) ; hh=int(hh) ;\
					milli-=(hh*60*60*1000) ; mn=(milli/(60*1000)) ; mn=int(mn) ;\
					milli-=(mn*60*1000) ; ss=(milli/1000) ; ss=int(ss) ;\
					milli-=(ss*1000) ; printf("%2d:%2d:%2d,%3d", hh, mn, ss, milli) }' | sed 's/ /0/g'
}

# corps du programme

echo $chaine | grep ":" > /dev/null 2>&1
		
if [[ $? -eq 0 ]]
then
	[[ $Debug > 1 ]] && printf "[Debug(2)] option = chaine2milli\n" >&2

	srt_conv_chaine2milli $chaine
else
	[[ $Debug > 1 ]] && printf "[Debug(2)] option = milli2chaine\n" >&2

	srt_conv_milli2chaine $chaine
fi

[[ $Debug > 0 ]] && printf "[Debug(1)] Fin\n" >&2
