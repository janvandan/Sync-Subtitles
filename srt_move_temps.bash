#!/bin/bash
# janvd.free.fr
# version 3.12

Debug=0

[[ $Debug > 0 ]] && printf "[Debug(1)] Demarrage\n" >&2

# test des arguments en entrée

if [[ $1 == "" ]] || [[ $2 == "" ]]
then
	printf "Erreur - Usage : $0 fichier_srt_a_recaler temps_en_milli\n"
	exit 2
else
	ls "$1" > /dev/null 2>&1
	if [[ $? != 0 ]]
	then
		printf "Erreur, le fichier $i n'existe pas\n" >&2
		exit 2
	else
		fichier_srt_ko=$1

		temps=$2

		[[ $Debug > 1 ]] && printf "[Debug(2)] fichier_srt_ko = $fichier_srt_ko, temps = $temps\n" >&2
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

# fonction qui converti une chaine en milli ; usage : srt_conv_temps chaine

function srt_conv_chaine2milli
{
	f_chaine=$1

	[[ $Debug > 1 ]] && printf "[Debug(2) (function srt_conv_chaine2milli)  f_chaine = $f_chaine\n" >&2

	echo $chaine | awk -F":|," '{ t=($1*60*60*1000 + $2*60*1000 + $3*1000 + $4) ; print t }'
}

# fonction qui converti le temps de milliseconde en hh:mm:ss,milli ; usage : srt_conv_milli2chaine temps_milli

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

				debut_para_ok=$(( debut_para_ko + temps ))
				fin_para_ok=$(( fin_para_ko + temps ))

				[[ $Debug > 1 ]] && printf "[Debug(2) debut_milli_ok = $debut_para_ok, fin_milli_ok = $fin_para_ok\n" >&2

				ch_debut_para_ok=$( srt_conv_milli2chaine $debut_para_ok )
				ch_fin_para_ok=$( srt_conv_milli2chaine $fin_para_ok )

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

printf "\a" >&2

[[ $Debug > 0 ]] && printf "[Debug(1)] Fin\n" >&2

exit 0
