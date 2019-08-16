#!/bin/bash
# janvd.free.fr
# version 1.01

Debug=0

[[ $Debug > 0 ]] && printf "[Debug(1)] Demarrage\n" >&2

# test des arguments en entrée

if [[ $1 == "" ]] || [[ $2 == "" ]]
then
	printf "Erreur - Usage : $0 fichier_srt1 fichier_srt2\n"
	exit 2
else
	ls "$1" > /dev/null 2>&1
	if [[ $? != 0 ]]
	then
		printf "Erreur, le fichier $1 n'existe pas\n" >&2
		exit 2
	else
		fichier_srt1="$1"

		ls "$2" > /dev/null 2>&1
		if [[ $? != 0 ]]
		then
			printf "Erreur, le fichier $2 n'existe pas\n" >&2
			exit 2
		else
			fichier_srt2=$2
			[[ $Debug > 1 ]] && printf "[Debug(2)] fichier_srt1 = $fichier_srt1, fichier_srt2 = $fichier_srt2\n" >&2
		fi
	fi
fi

# fonction qui calcul le temps en milli secondes de debut (0) ou de fin (1) du paragraphe numero numero ; usage : srt_temps 0|1 numero nom_srt

function srt_temps
{
	option=$1
	f_para=$2
	f_fichier="$3"

	[[ $Debug > 1 ]] && printf "[Debug(2) (function srt_temps)  f_option = $option, f_para = $f_para, f_fichier = $f_fichier\n" >&2

	if [[ $option -eq 1 ]]
	then
		sed 's///' "$f_fichier" | grep -A 1 "^$f_para$" | tail -1 \
					| awk -F":| --> |," '{ t2=($5*60*60*1000 + $6*60*1000 + $7*1000 + $8) ;\
							print t2 }'
	else
		sed 's///' "$f_fichier" | grep -A 1 "^$f_para$" | tail -1 \
					| awk -F":| --> |," '{ t1=($1*60*60*1000 + $2*60*1000 + $3*1000 + $4) ;\
							print t1 }'
	fi
}

# fonction qui converti le temps de milliseconde en hh:mm:ss,milli ; usage : srt_conv_temps temps_milli

function srt_conv_temps
{
	f_temps=$1

	[[ $Debug > 1 ]] && printf "[Debug(2) (function srt_conv_temps)  f_option = $f_temps\n" >&2

	echo $f_temps | awk '{ milli=$1 ; hh=(milli/(60*60*1000)) ; hh=int(hh) ;\
					milli-=(hh*60*60*1000) ; mn=(milli/(60*1000)) ; mn=int(mn) ;\
					milli-=(mn*60*1000) ; ss=(milli/1000) ; ss=int(ss) ;\
					milli-=(ss*1000) ; printf("%2d:%2d:%2d,%3d", hh, mn, ss, milli) }' | sed 's/ /0/g'
}

# fonction qui prend le numero du dernier sous titre du fichier srt, usage nom_srt

function srt_dernier_para
{
	fichier_in="$1"
	f_retour=0

	[[ $Debug > 1 ]] && printf "[Debug(2)] (function srt_dernier_para) fichier_in = $fichier_in\n" >&2
	
	sed 's///' "$fichier_in" | grep "^[[:digit:]][[:digit:]]*$" > /dev/null 2>&1
	if [[ $? != 0 ]]
	then
		printf "Erreur, fichier $fichier_in n'est pas un fichier srt !\n" >&2
		f_retour=2
	else
		sed 's///' "$fichier_in" | grep "^[[:digit:]][[:digit:]]*$" | tail -1 
	fi
	
	return $f_retour
}

# fonction qui prend le numero du premier sous titre du fichier srt, usage nom_srt

function srt_premier_para
{
	fichier_in="$1"
	f_retour=0

	[[ $Debug > 1 ]] && printf "[Debug(2)] (function srt_premier_para) fichier_in = $fichier_in\n" >&2
	
	sed 's///' "$fichier_in" | grep "^[[:digit:]][[:digit:]]*$" > /dev/null 2>&1
	if [[ $? != 0 ]]
	then
		printf "Erreur, fichier $fichier_in n'est pas un fichier srt !\n" >&2
		f_retour=2
	else
		sed 's///' "$fichier_in" | grep "^[[:digit:]][[:digit:]]*$" | head -1 
	fi
	
	return $f_retour
}

# corps du programme

premier_para1=$( srt_premier_para "$fichier_srt1" )

[[ $Debug > 1 ]] && printf "[Debug(2)] premier para 1 = $premier_para1\n" >&2

temps_p1=$( srt_temps 0 $premier_para1 "$fichier_srt1" )

[[ $Debug > 1 ]] && printf "[Debug(2)] temps p 1 = $temps_p1\n" >&2

premier_para2=$( srt_premier_para "$fichier_srt2" )

[[ $Debug > 1 ]] && printf "[Debug(2)] premier para 2 = $premier_para2\n" >&2

temps_p2=$( srt_temps 0 $premier_para2 "$fichier_srt2" )

[[ $Debug > 1 ]] && printf "[Debug(2)] temps p 2 = $temps_p2\n" >&2

if [[ $temps_p1 -ne $temps_p2 ]]
then
	printf "Les deux premiers time mark des deux fichiers ne sont pas identiques. Lancement de srt_move_temps.bash pour les recaler.\n" >&2

	delta_temps=$(( temps_p2 - temps_p1 ))

	[[ $Debug > 1 ]] && echo "[Debug(2)] delta_temps = $delta_temps" >&2

	ls "./srt_move_temps.bash" > /dev/null 2>&1
	if [[ $? != 0 ]]
	then
		printf "Erreur, le fichier ./srt_move_temps.bash est introuvable.\n" >&2
		exit 2
	else
		date_bckp=$( date "+%Y%m%d%H%M%S" )
		fichier_backup="$fichier_srt1""$date_bckp"
		cp "$fichier_srt1" "$fichier_backup"
		
		[[ $Debug > 1 ]] && echo "[Debug(2)] creation sauvegarde = $fichier_backup" >&2
		./srt_move_temps.bash "$fichier_backup" $delta_temps > "$fichier_srt1"
		code_retour=$?
		[[ $Debug > 1 ]] && echo "[Debug(2)] code retour = $code_retour" >&2

		file "$fichier_backup" | grep CRLF > /dev/null 2>&1
		if [[ $? -eq 0 ]]
		then
			[[ $Debug > 1 ]] && printf "[Debug(2)] CRLF dans le fichier original, ajoute dans le fichier en sortie.\n" >&2
			date_bckp=$( date "+%Y%m%d%H%M%S" )
			fichier_backup="$fichier_srt1""$date_bckp"
			cp "$fichier_srt1" "$fichier_backup"
			sed 's/$//' "$fichier_backup" > "$fichier_srt1"
		fi
	fi
else
	code_retour=0
	printf "Les deux premiers time mark des deux fichiers sont déjà identiques.\n" >&2
fi

[[ $Debug > 0 ]] && printf "[Debug(1)] Fin\n" >&2

exit $code_retour
