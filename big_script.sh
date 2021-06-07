# Author       : Mikita Zenevich ( zenevichnikita@gmail.com )
# Created On       : 08.05.2021
# Last Modified By : Mikita Zenevich ( zenevichnikita@gmail.com )
# Last Modified On : 08.05.2021
# Version          : 1.0
#
# Description      :
# Simple video editor.
# 
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)
#!/bin/bash
OPT=0

while getopts 'vhf:' OPTION; do
  case "$OPTION" in
    v)
      echo "version 1.0"
	  OPT=10
      ;;

    h)
      echo "help"
      echo "This is simple video editor.You can use options"
      echo "-v to get your version"
      echo "-h to get help "
      echo "-f to set name of file to edit "
      echo " Then you will see graphic menu and edit your file"
      echo " If you want to get timestamp to cut video or make screenshot use q "
      OPT=10
	  ;;

    f)
      NAZWA="$OPTARG"
      ;;
    ?)
      echo "wrong parameter"
      OPT=10
	  exit 1
      ;;
  esac
done

while [ "$OPT" != 10 ]
do

    M1="1. Nazwa pliku: $NAZWA"
    M2="2. Konvertacja w avi - avi"
    M3="3. Skalowac rozdzielczosc"
    M4="4. Cut video"
    M5="5. Dodaj napisy - srt"
    M6="6. Dodaj scizke dzwiekowa -avi -mp3"
    M7="7. Dodaj znak wodny -png"
    M8="8. Zrob screenshot"
	M9="9. Get audio"
	M10="10. Encrease volume"
    M11="11.PLAY"
    M12="12.END"
    MENU=("$M1" "$M2" "$M3" "$M4" "$M5" "$M6" "$M7" "$M8" "$M9" "$M10" "$M11" "$M12")
    OPT=$(zenity --list --column=MENU "${MENU[@]}" --height 400 --width 300)
    case "$OPT" in
	$M1)
	    NAZWA=$(zenity --file-selection --file-filter=""*.mp4" "*.mkv"")
	    NAZWA_FORMATU="${NAZWA##*.}"
	    NAZWA_PLIKU="${NAZWA%.*}"
		if [ -e $NAZWA ]
		then
	    echo $NAZWA_PLIKU
		else
		echo "plik nie istnieje"
		NAZWA_PLIKU=""
		NAZWA=""
		NAZWA_FORMATU=""
		fi
	   ;;
	$M2)
	    if [ -n "$NAZWA" ]; then
		
		ffmpeg -i $NAZWA "$NAZWA_PLIKU".avi
	    else
		zenity --error --text "Nazwa pliku jest pusta"
	    fi
	    ;;
	$M3)
	    #skalowac rozdzielczosc
		
	    if [ -n "$NAZWA" ]; then 
        WIDTH=$(ffprobe -v error -show_entries stream=width,height -of csv=p=0:s=x $NAZWA | cut -d'x' -f 1)
        HEIGHT=$(ffprobe -v error -show_entries stream=width,height -of csv=p=0:s=x $NAZWA | cut -d'x' -f 2)
		echo $WIDTH
		echo $HEIGHT
		SKALE=$(zenity --scale --min-value=10 --max-value=150 --value=50 --step=10 )
		WIDTH=$(( $SKALE * $WIDTH / 100 ))	
		HEIGHT=$(( $SKALE * $HEIGHT / 100 ))	
		echo $WIDTH
		echo $HEIGHT
		ffmpeg -i $NAZWA -s "$WIDTH"x"$HEIGHT" "$NAZWA_PLIKU"_"$WIDTH"x"$HEIGHT"."$NAZWA_FORMATU"
	    else
		zenity --error --text "Nazwa pliku jest pusta"
	    fi
	    ;;
	$M4)
		if [ -n "$NAZWA" ]; then 
		DATA_FILE=$(mktemp)
		ffplay $NAZWA 2> $DATA_FILE
		#TIMESTAMP1="00:00:10"
		TIMESTAMP1=$(cat -v $DATA_FILE |sed 's/M/\n/g' | grep  "A-V"  | tail  -1 | sed 's/^ *//g'|cut -d' ' -f 1)
		echo $TIMESTAMP1
		ffplay $NAZWA -ss $TIMESTAMP1 2> $DATA_FILE
		#TIMESTAMP2="00:01:10"
		TIMESTAMP2=$(cat -v $DATA_FILE |sed 's/M/\n/g' | grep  "A-V"  | tail  -1 | sed 's/^ *//g'|cut -d' ' -f 1)
		echo $TIMESTAMP2
		ffmpeg -i $NAZWA -ss $TIMESTAMP1 -t $TIMESTAMP2 -c copy "$NAZWA_PLIKU"_cut."$NAZWA_FORMATU"
		#ffplay "$NAZWA_PLIKU"_cut."$NAZWA_FORMATU"
	    else
		zenity --error --text "Nazwa pliku jest pusta"
	    fi
	    ;;
	$M5)            
	    NAPISY=$(zenity --file-selection --file-filter=*.srt )
		echo "$NAPISY"
		if [ -n "$NAZWA" ]; then 
		ffmpeg -i $NAZWA -i $NAPISY -c copy -c:s copy  "$NAZWA_PLIKU"_sub.mkv
		rm $NAZWA
		NAZWA="$NAZWA_PLIKU"_sub.mkv
		NAZWA_FORMATU="${NAZWA##*.}"
	    NAZWA_PLIKU="${NAZWA%.*}"
		else
		zenity --error --text "Nazwa pliku lub napisy sa puste "
	    fi
	    ;;
	$M6)
	    DZWIEK=$(zenity --file-selection --file-filter=""*.mp3" "*.avi"")
		if [ -n "$NAZWA" ]; then 
		ffmpeg -i $NAZWA -i $DZWIEK -c copy -map 0:v:0 -map 1:a:0 "$NAZWA_PLIKU"_audio."$NAZWA_FORMATU"
		rm $NAZWA
		NAZWA="$NAZWA_PLIKU"_audio."$NAZWA_FORMATU"
		NAZWA_FORMATU="${NAZWA##*.}"
	    NAZWA_PLIKU="${NAZWA%.*}"
		else
		zenity --error --text "Nazwa pliku lub napisy sa puste "
	    fi
	    ;;
	$M7)
	    WATERMARK=$(zenity --file-selection --file-filter=""*.png" ")
		if [ -n "$NAZWA" ]; then 
		ffmpeg -i  $NAZWA -i $WATERMARK -filter_complex "overlay=10:10" "$NAZWA_PLIKU"_watermark."$NAZWA_FORMATU"
		NAZWA="$NAZWA_PLIKU"_watermark."$NAZWA_FORMATU"
		NAZWA_FORMATU="${NAZWA##*.}"
	    NAZWA_PLIKU="${NAZWA%.*}"
		else
		zenity --error --text "Nazwa pliku lub napisy sa puste "
	    fi
	    ;;
	$M8)
	    if [ -n "$NAZWA" ]; then 
		FOLDER=$(mktemp)
    	ffplay $NAZWA 2> $FOLDER
		# data.txt cannot be printed??
		TIMESTAMP=$(cat -v $FOLDER |sed 's/M/\n/g' | grep  "A-V"  | tail  -1 | sed 's/^ *//g'|cut -d' ' -f 1)
		echo $TIMESTAMP
		#TIMESTAMP="00:00:30"
		ffmpeg -i $NAZWA -ss $TIMESTAMP -frames:v 1 "$NAZWA_PLIKU"_screenshot.jpg
	    else
		zenity --error --text "Nazwa pliku jest pusta"
	    fi
	    ;;
	$M9)
	    if [ -n "$NAZWA" ]; then	
		ffmpeg -i $NAZWA "$NAZWA_PLIKU".mp3
	    else
		zenity --error --text "Nazwa pliku jest pusta"
	    fi
	    ;;
	$M10)
	    if [ -n "$NAZWA" ]; then	
		SKALE=$(zenity --scale --min-value=1 --max-value=10 --value=2)
		ffmpeg -i $NAZWA -c:v copy -af 'volume=100' "$NAZWA_PLIKU"_loud."$NAZWA_FORMATU"
	    else
		zenity --error --text "Nazwa pliku jest pusta"
	    fi
	    ;;
	$M11)
	    if [ -n "$NAZWA" ]; then 
		ffplay $NAZWA
		
	    else
		zenity --error --text "Nazwa pliku jest pusta"
	    fi
	   ;;
	$M12)
	    OPT=10
	    ;;
    esac
done
