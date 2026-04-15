#!/bin/bash

init_board() {
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

RED='\033[0;31m'
GREEN='\033[0;32m'
BASE='\033[0m'

cross="${RED}X${BASE}"
circle="${GREEN}O${BASE}"

score_x=0
score_o=0

print_board() {
    echo -e "Wynik: X:$score_x  O:$score_o\n"

    for row in 0 3 6; do
        line=""
        for col in 0 1 2; do
            idx=$((row + col))
            cell="${board[$idx]}"

            line+=" $cell "
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

win_check() {
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


while true; do
    init_board
    player=$cross
    free_spot_count=9

    while true; do
        clear
        print_board

        echo -e "Gracz $player, wybierz pole (0-8):"
        read move

        if [[ $move -ge 0 && $move -le 8 && "${board[$move]}" != $cross && "${board[$move]}" != $circle ]]; then
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
            echo -e "Gracz $player wygrywa!"

            if [[ "$player" == "$cross" ]]; then
                score_x=$((score_x + 1))
            else
                score_o=$((score_o + 1))
            fi

            sleep 2
            break
        fi

        if [[ $free_spot_count -eq 0 ]]; then
            clear
            print_board
            echo "Remis!"
            sleep 1
            break
        fi

        if [[ "$player" == "$cross" ]]; then
            player=$circle
        else
            player=$cross
        fi
    done
done
