#!/bin/bash

SAVE_FILE="save.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
BASE='\033[0m'

cross="X"
circle="O"

score_x=0
score_o=0


init_board()
{
    board=(0 1 2
           3 4 5
           6 7 8)
}

solutions=("0 1 2"
           "3 4 5"
           "6 7 8"

           "0 3 6"
           "1 4 7"
           "2 5 8"

           "0 4 8"
           "2 4 6")

get_color() 
{
    if [[ "$1" == $cross ]]; then
        echo -e "${RED}X${BASE}"
    elif [[ "$1" == $circle ]]; then
        echo -e "${GREEN}O${BASE}"
    else
        echo "$1"
    fi
}


print_board()
{
    echo -e "Wynik: X=$score_x  O=$score_o\n"

    for row in 0 3 6; do
        line=""
        for col in 0 1 2; do
            idx=$((row + col))
            cell="${board[$idx]}"
            colored=$(get_color "$cell")

            line+=" $colored "
            if [[ $col -lt 2 ]]; then
                line+="|"
            fi
        done
        echo -e "$line"
        if [[ $row -lt 6 ]]; then
            echo "---+---+---"
        fi
    done
}


win_check() 
{
    for s in "${solutions[@]}"; do
        positions=($s)
        p=${board[${positions[0]}]}

        if [[ "${board[${positions[0]}]}" == "$p" &&
              "${board[${positions[1]}]}" == "$p" &&
              "${board[${positions[2]}]}" == "$p" ]]; then
            return 0
        fi
    done
    return 1
}


save_game()
{
    {
        echo "$score_x $score_o"
        echo "$player"
        echo "$free_spot_count"
        echo "${board[@]}"
    } > "$SAVE_FILE"
}


load_game()
{
    if [[ -f "$SAVE_FILE" ]]; then
        echo "Wczytano zapis gry"
        read score_x score_o < "$SAVE_FILE"
        read player < <(sed -n '2p' "$SAVE_FILE")
        read free_spot_count < <(sed -n '3p' "$SAVE_FILE")
        read -a board < <(sed -n '4p' "$SAVE_FILE")
    else
        init_board
        player=$cross
        free_spot_count=9
    fi
}


clear
echo "1 - Nowa gra"
echo "2 - Wczytaj grę"
read choice

if [[ "$choice" == "2" ]]; then
    load_game
else
    init_board
    player=$cross
    free_spot_count=9
fi


while true; do
    while true; do
        clear
        print_board

        echo -e "Gracz $(get_color "$player"), wybierz pole (0-8) | 9 - zapis"
        read move

        if [[ "$move" == "9" ]]; then
            save_game
            continue
        fi


        if [[ $move =~ ^[0-8]$ && "${board[$move]}" != "X" && "${board[$move]}" != "O" ]]; then
            free_spot_count=$((free_spot_count - 1))
            board[$move]=$player
        else
            echo "Niepoprawny ruch!"
            sleep 1
            continue
        fi


        if win_check; then
            clear
            print_board
            echo -e "Gracz $(get_color "$player") wygrywa"

            if [[ "$player" == "X" ]]; then
                score_x=$((score_x + 1))
            else
                score_o=$((score_o + 1))
            fi

            sleep 1
            break
        fi

        if [[ $free_spot_count -eq 0 ]]; then
            clear
            print_board
            echo "Remis"
            sleep 1
            break
        fi

        if [[ "$player" == $cross ]]; then
            player=$circle
        else
            player=$cross
        fi
    done

    init_board
    free_spot_count=9
done
