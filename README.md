################################
# synchroniser les sous titres #
################################
# 2.00

La plupart des films sont fournis avec leurs sous titres en anglais. Régulièrement, les sous titres en français ne sont pas inclus.
De même, il est souvent possible de trouver les sous titres en français sur internet mais désynchronisé par rapport à notre film original.
D'où l'idée d'utiliser la référence des sous titres en anglais pour synchroniser les sous titres en français trouvés par ailleurs.

Ci-dessous, et pour l'exemple, nous souhaitons avoir les sous-titres en français du film AVA_FILM. Nous avons les sous titres en anglais de AVA_FILM parfaitement synchronisés (fichier AVA_FILM_en.srt). Nous avons trouvé par ailleurs les sous-titres en français (fichier AVA_FILM_fr.srt), mais complètement désynchronisés quand on essaye de regarder AVA_FILM avec. But du jeu, créer un fichier de sous titres en français aussi bien synchronisés que les sous titres en anglais. Bien sûr sans avoir à lire la moitié des dialogues avant de voir le film, ni à visionner la vidéo avec un chrono... Inconvénient, il faut oser utiliser les lignes de commandes unix.

Pour ce faire, quatre scripts :

	srt_cale_debut.bash (*)
	srt_auto_adjust.bash (*)
	srt_conv_temps.bash (**)
	srt_move_temps.bash

	Seuls les scripts (*) sont à utiliser, le(s) autre(s) sont appelés par les précédents. (**) script(s) fourni(s) en bonus...

1) Mode opératoire bref...

	a) Verifier avec un éditeur que les deux fichiers de sous-titres correspondent : c-a-d que le premier dialogue d'AVA_FILM_en.srt est la traduction du premier dialogue d'AVA_FILM_fr.srt, idem pour le dernier dialogue.

	b) exécuter le premier script :

		$ ./srt_cale_debut.bash AVA_FILM_fr.srt AVA_FILM_eng.srt
		

	c) exécuter le deuxième script une première fois pour le ratio :

		$ ./srt_auto_adjust.bash AVA_FILM_fr.srt AVA_FILM_eng.srt 
		Pour le calcul de ratio, le premier paragraphe et le dernier paragraphe des deux fichiers doivent correspondre.
		
		-.04268388814214428833

	d) exécuter à nouveau le deuxième script pour caler les sous-titres suivant le ratio calculé :

		$ ./srt_auto_adjust.bash AVA_FILM_fr.srt -.04268388814214428833 > AVA_FILM_frOK.srt
		Le deuxième argument n'est pas un fichier, donc c'est le ratio temps_fr/temps_ok
		Ne pas oublier de rajouter les CRLF dans le fichier final si l'original en contenait avec la commande ( sed 's/$/^M/' ), ^M étant obtenu par Ctrl+V puis Ctrl+M


	e) on vérifie la nécessité d'appliquer les CRLF ou non

		$ file AVA_FILM_frOK.srt
		AVA_FILM_frOK.srt: ISO-8859 text, with CRLF line terminators

	L'original comportait des CRLF en fin de ligne, on les remets pour être conforme à l'original :

		$ sed 's/$/^M/' AVA_FILM_frOK.srt > AVA_FILM_frOK_CRLF.srt

	C'est fini...


2) Mode opératoire détaillé avec srt_cale_debut.bash et srt_auto_adjust.bash

Ce script permet de recaler les sous titres d'un fichier srt désynchronisé en fonction d'un fichier de sous titres de référence et donc non désynchronisé.
Pour fonctionner, il a besoin de deux fichiers sources : les sous titres correctement synchronisés (en anglais par exemple) et le fichier des sous titres à recaler (en français par exemple).
Il est à noter que la désynchronisation de sous-titres est rarement linéaire, c-a-d que le décalage en temps du premier sous titre et du dernier sous titre soit le même. Si c'est le cas, le programme srt_move_temps suffit, sinon srt_auto_adjust.bash est nécessaire.

La procédure se fait en deux temps (*) :

	a) On demande au script de calculer le ratio temporel, décalage non linéaire entre les deux sources.

		srt_auto_adjust.bash fichier_srt_a_recaler fichier_srt_bien_calé

	b) On demande au script d'appliquer ce ratio sur les sous titres à recaler

		srt_auto_adjust.bash fichier_srt_a_recaler ratio

(*) Cette procédure a un pré-requis : les deux fichiers doivent démarrer au même time mark. C'est rarement le cas, aussi il est souvent nécessaire de décaler le fichier à resynchroniser (en français dans notre cas) pour qu'il démarre au même time mark que le fichier référence (en anglais dans notre cas).
Ce qui permet de vérifier également que les premiers sous titres des deux fichiers correspondent, c-a-d que le premier dialogue est identique dans les deux cas (en anglais et en français dans notre exemple). En effet, il arrive que la version anglaise (ou version originale) soit pour les sourds et mal entendants, dans ce cas il y a plus de sous-titre pour décrire la musique, l'ambiance... Si c'est le cas, il faut supprimmer avec un éditeur les lignes des premiers et des derniers sous titres qui ne sont pas les traductions lues dans l'autre fichier de sous-titres.

	exemple : Pour le vérifier via ligne de commande ou via un editeur de texte quelconque...

		$ head -3 AVA_FILM_en.srt
		1
		00:02:45,123 --> 00:02:48,208
		"Do you ever have emotions
		$ head -3 AVA_FILM_fr.srt
		1
		00:02:36,640 --> 00:02:39,598
		"Avez-vous eu des émotions
	
	On constate que le premier démarre à 2 mn, 45 s et 123 millisecondes, alors que le deuxième démarre à 2 mn, 36 s et 640 millisecondes...

Pour caler le démarrage, on utilisera d'abord le script srt_cale_debut.bash. Ce script peut être utilisé systématiquement puisqu'il vérifie par lui même la nécessité ou non de recaler les deux fichiers de sous-titres entre eux.

	exemple : 
		
		$ ./srt_cale_debut.bash AVA_FILM_fr.srt AVA_FILM_eng.srt

		S'il y a un décalage, le premier fichier sera remplacé par un fichier avec le bon time mark.

Une fois fait, on peut utiliser srt_auto_adjust.bash.

	exemple :
	
		$ ./srt_auto_adjust.bash AVA_FILM_frCALE_CRLF.srt AVA_FILM_en.srt 
		Pour le calcul de ratio, le premier paragraphe et le dernier paragraphe des deux fichiers doivent correspondre.
		
		-.04268388814214428833

	Dans notre exemple, le ratio a appliquer est donc -0,04268388814214428833.

		$ ./srt_auto_adjust.bash AVA_FILM_frCALE_CRLF.srt -.04268388814214428833 > AVA_FILM_frOK.srt
		Le deuxième argument n'est pas un fichier, donc c'est le ratio temps_fr/temps_ok
		Ne pas oublier de rajouter les CRLF dans le fichier final si l'original en contenait avec la commande ( sed 's/$/^M/' ), ^M étant obtenu par Ctrl+V puis Ctrl+M

	On fait ce que l'on nous dit de faire :

		$ sed 's/$/^M/' AVA_FILM_frOK.srt > AVA_FILM_frOK_CRLF.srt

	Il est maintenant possible à l'aide du fichier obtenu AVA_FILM_frOK_CRLF.srt de ragarder le film avec les sous titres francais correctement synchronisés.

3) Annexe 1 : srt_conv_temps.bash

Ce script permet de manipuler les valeures temporelles (time mark) des fichiers sous titres (srt). Il permet de passer d'une marque HH:MM:SS,mmm en millisecondes et inversement.

	srt_conv_temps.bash chaine_a_convertir(HH:MM:SS,mmm) ou en_milli

Il nous est utile pour calculer en milliseconde le décalage entre nos deux sources.

	exemple :

		$ ./srt_conv_temps.bash 00:02:45,123
		165123
		$ ./srt_conv_temps.bash 00:02:36,640
		156640

	La difference entre les deux est donc de 165123 - 156640 = 8483 millisecondes

4) Annexe 2 : srt_move_temps.bash

Ce script permet de décaler du même délai temporel l'ensemble des sous titres d'un fichier srt.

La procédure est simple :

	exécuter : srt_move_temps.bash fichier_srt_a_recaler temps_en_milli

Où "temps_en_milli" est le décalage en milliseconde à prendre en compte (ce décalage peut être négatif).

	exemple :

		$ ./srt_move_temps.bash AVA_FILM_fr.srt 8483 > AVA_FILM_frCALE.srt
		Ne pas oublier de rajouter les CRLF dans le fichier final si l'original en contenait avec la commande ( sed 's/$/^M/' ), ^M étant obtenu par Ctrl+V puis Ctrl+M

	Le script nous rappel de rajouter le code de fin de ligne CR+LF s'il était présent initialement (peut être vérifié avec la commande en ligne "file AVA_FILM_fr.srt").

		$ sed 's/$/^M/' AVA_FILM_frCALE.srt > AVA_FILM_frCALE_CRLF.srt

	On verifie que l'on a bien le même démarrage :
		$ head -2 AVA_FILM_en.srt
		1
		00:02:45,123 --> 00:02:48,208
		$ head -2 AVA_FILM_frCALE_CRLF.srt 
		1
		00:02:45,123 --> 00:02:48,081

	On peut maintenant utiliser srt_auto_adjust.bash
