#!/bin/bash
# janvd.free.fr
# version 3.13

Debug=0

[[ $Debug > 0 ]] && printf "[Debug(1)] Demarrage\n" >&2

# test des arguments en entrée

if [[ $1 == "" ]] || [[ $2 == "" ]]
then
	printf "Erreur - Usage : $0 fichier_srt_a_recaler fichier_srt_bien_calé || ratio\n"
	exit 2
else
	ls "$1" > /dev/null 2>&1
	if [[ $? != 0 ]]
	then
		printf "Erreur, le fichier $1 n'existe pas\n" >&2
		exit 2
	else
		fichier_srt_ko=$1

		ls "$2" > /dev/null 2>&1
		if [[ $? != 0 ]]
		then
			printf "Le deuxième argument n'est pas un fichier, donc c'est le ratio temps_fr/temps_ok\n" >&2
			ratio_temps=$2
			option=ratio
			[[ $Debug > 1 ]] && printf "[Debug(2)] ratio = $ratio_temps\n" >&2
		else
			fichier_srt_ok=$2
			[[ $Debug > 1 ]] && printf "[Debug(2)] fichier_srt_ok = $fichier_srt_ok, fichier_srt_ko = $fichier_srt_ko\n" >&2

			# rappel utilisation

			printf "Pour le calcul de ratio, le premier paragraphe et le dernier paragraphe des deux fichiers doivent correspondre.\n\n" >&2
		fi
	fi
fi

# fonction qui affiche une animation pendant le traitement

export ordre=1

function AfficheTravail
{
	# Motifs : | / - \ | / - \ 

	if [[ $ordre == 9 ]]
	then
		ordre=1
	fi  

	case $ordre in
		1)  
			printf "\r|" >&2 ;;
		2)  
			printf "\r/" >&2 ;;
		3)  
			printf "\r-" >&2 ;;
		4)  
			printf "\r\\" >&2 ;;
		5)  
			printf "\r|" >&2 ;;
		6)  
			printf "\r/" >&2 ;;
		7)  
			printf "\r-" >&2 ;;
		8)  
			printf "\r\\" >&2 ;;
	esac

	ordre=$(( ++ordre ))
}

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

premier_para_ko=$( srt_premier_para "$fichier_srt_ko" )

[[ $Debug > 1 ]] && printf "[Debug(2) premier para ko = $premier_para_ko\n" >&2

temps_p_ko=$( srt_temps 0 $premier_para_ko "$fichier_srt_ko" )

[[ $Debug > 1 ]] && printf "[Debug(2) temps p ko = $temps_p_ko\n" >&2

if [[ $option != "ratio" ]]
then
	premier_para_ok=$( srt_premier_para "$fichier_srt_ok" )

	[[ $Debug > 1 ]] && printf "[Debug(2) premier para ok = $premier_para_ok\n" >&2

	temps_p_ok=$( srt_temps 0 $premier_para_ok "$fichier_srt_ok" )

	[[ $Debug > 1 ]] && printf "[Debug(2) temps p ok = $temps_p_ok\n" >&2

	dernier_para_ko=$( srt_dernier_para "$fichier_srt_ko" )
	dernier_para_ok=$( srt_dernier_para "$fichier_srt_ok" )

	[[ $Debug > 1 ]] && printf "[Debug(2) dernier para ko = $dernier_para_ko, dernier para ok = $dernier_para_ok\n" >&2

	temps_f_ko=$( srt_temps 0 $dernier_para_ko "$fichier_srt_ko" )
	temps_f_ok=$( srt_temps 0 $dernier_para_ok "$fichier_srt_ok" )

	[[ $Debug > 1 ]] && printf "[Debug(2) temps f ko = $temps_f_ko, temps f ok = $temps_f_ok\n" >&2

	if [[ $temps_p_ko -ne $temps_p_ok ]]
	then
		printf "Erreur, les deux premiers time mark des deux fichiers ne sont pas identiques. Il faut synchroniser les deux fichiers sur le time mark du fichier ok. Utiliser srt_move_temps.\n" >&2
	else
		# On part du principe que les fichiers sont désynchronisés de manière progressive du
		# à la difference de fps à l'enregistrement. On calcul le décalage par seconde de fps
		# pour ensuite l'appliquer au fichier à recaler si nécessaire. La différence est
		# calculée à partir du premier sous titre.

		delta_temps=$(( temps_f_ko - temps_f_ok ))

		ratio_temps=$( bc -l <<<"$delta_temps / ($temps_f_ko - $temps_p_ko)" )

		[[ $Debug > 1 ]] && echo "[Debug(2) ratio_temps = $ratio_temps" >&2

		echo "$ratio_temps" | grep '^\.' > /dev/null 2>&1
		if [[ $? -eq 0 ]]
		then
			[[ $Debug > 1 ]] && echo "[Debug(2) ratio_temps = $ratio_temps (.xx)" >&2
			echo "$ratio_temps" | sed 's/^\./0\./'
			exit 0
		else
			echo "$ratio_temps" | grep '^-\.' > /dev/null 2>&1
			if [[ $? -eq 0 ]]
			then
				[[ $Debug > 1 ]] && echo "[Debug(2) ratio_temps = $ratio_temps (-.xx)" >&2
				sed 's/^-\./-0\./' << EOF
$ratio_temps
EOF
				exit 0
			else
				[[ $Debug > 1 ]] && echo "[Debug(2) ratio_temps = $ratio_temps (x.xx)" >&2
				echo "$ratio_temps"
				exit 0
			fi
		fi
	fi
else

	num_para_new=1

	i=1
	sed 's///' "$fichier_srt_ko" | while read line
	do
		AfficheTravail

		if [[ "$line" != "" ]]
		then
			case $i in
				1)
					num_para_ko=$line
					[[ $Debug > 1 ]] && printf "[Debug(2) para_ko = $num_para_ko\n" >&2
					printf "$num_para_new\n"
					i=$(( ++i )) ;;
				2)
					[[ $Debug > 1 ]] && printf "[Debug(2) time_ko = $line\n" >&2

					debut_para_ko=$( echo $line | awk -F":| --> |," '{ t1=($1*60*60*1000 + $2*60*1000 + $3*1000 + $4) ; print t1 }' )
					fin_para_ko=$( echo $line | awk -F":| --> |," '{ t2=($5*60*60*1000 + $6*60*1000 + $7*1000 + $8) ; print t2 }' )
					
					[[ $Debug > 1 ]] && printf "[Debug(2) debut_milli_ko = $debut_para_ko, fin_milli_ko = $fin_para_ko\n" >&2

					debut_para_ok=$( bc -l <<<"( $debut_para_ko - $temps_p_ko ) * -1 * $ratio_temps + $debut_para_ko" | cut -d. -f1 )
					fin_para_ok=$( bc -l <<<"( $fin_para_ko - $temps_p_ko ) * -1 * $ratio_temps + $fin_para_ko" | cut -d. -f1 )

					[[ $Debug > 1 ]] && printf "[Debug(2) debut_milli_ok = $debut_para_ok, fin_milli_ok = $fin_para_ok\n" >&2

					ch_debut_para_ok=$( srt_conv_temps $debut_para_ok )
					ch_fin_para_ok=$( srt_conv_temps $fin_para_ok )

					[[ $Debug > 1 ]] && printf "[Debug(2) debut_ch_ok = $ch_debut_para_ok, fin_ch_ok = $ch_fin_para_ok\n" >&2

					printf "$ch_debut_para_ok --> $ch_fin_para_ok\n"

					i=$(( ++i )) ;;
				*)
					echo "$line"
					i=$(( ++i )) ;;
			esac
		else
			if [[ $i -ne 1 ]]
			then
				printf "\n"
				i=1
				num_para_new=$(( ++num_para_new ))
			fi
		fi
	done
	# Rappel sur les fichiers CRLF

	printf "\rNe pas oublier de rajouter les CRLF dans le fichier final si l'original en contenait avec la commande ( sed 's/$/^M/' ), ^M étant obtenu par Ctrl+V puis Ctrl+M\n" >&2

fi

printf "\a" >&2

[[ $Debug > 0 ]] && printf "[Debug(1)] Fin\n" >&2

exit 0
