#!/bin/bash

SAVE_FILE="save.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
BASE='\033[0m'

cross="X"
circle="O"

score_x=0
score_o=0

ai_opponent=true

starting_player=$cross

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
    local b=("$@")

    for s in "${solutions[@]}"; do
        positions=($s)
        p=${b[${positions[0]}]}

        if [[ "${b[${positions[0]}]}" == "$p" &&
              "${b[${positions[1]}]}" == "$p" &&
              "${b[${positions[2]}]}" == "$p" ]]; then
            return 0
        fi
    done
    return 1
}


play_computer()
{
    # win
    for i in {0..8}; do
        if [[ ${board[$i]} != $cross && ${board[$i]} != $circle ]]; then
            board[$i]=$circle
            if win_check "${board[@]}"; then
                return
            fi
            board[$i]=$i
        fi
    done

    # block
    for i in {0..8}; do
        if [[ ${board[$i]} != $cross && ${board[$i]} != $circle ]]; then
            board[$i]=$cross
            if win_check "${board[@]}"; then
                board[$i]=$circle
                return
            fi
            board[$i]=$i
        fi
    done

    # center
    if [[ ${board[4]} != $cross && ${board[4]} != $circle ]]; then
        board[4]=$circle
        return
    fi

    # corners
    for i in 0 2 6 8; do
        if [[ ${board[$i]} != $cross && ${board[$i]} != $circle ]]; then
            board[$i]=$circle
            return
        fi
    done

    # edges
    for i in 1 3 5 7; do
        if [[ ${board[$i]} != $cross && ${board[$i]} != $circle ]]; then
            board[$i]=$circle
            return
        fi
    done
}


save_game()
{
    {
        echo "$score_x $score_o"
        echo "$starting_player"
        echo "$player"
        echo "$free_spot_count"
        echo "${board[@]}"
    } > "$SAVE_FILE"
}


load_game()
{
    if [[ -f "$SAVE_FILE" ]]; then
        echo "Wczytano zapis gry"

        mapfile -t lines < "$SAVE_FILE"

        read score_x score_o <<< "${lines[0]:-0 0}"
        starting_player="${lines[1]:-$cross}"
        player="${lines[2]:-$starting_player}"
        free_spot_count="${lines[3]:-9}"
        board_line="${lines[4]:-0 1 2 3 4 5 6 7 8}"

        read -a board <<< "$board_line"

    else
        init_board
        starting_player=$cross
        player=$starting_player
        free_spot_count=9
    fi
}


while true; do
    clear
    echo "1 - Nowa gra"
    echo "2 - Wczytaj grę"
    echo "3 - Przeciwnik AI: $ai_opponent"
    echo "Wybierz (1-3)"
    read choice

    if [[ "$choice" == "1" ]]; then
        init_board
        player=$starting_player
        free_spot_count=9
        break

    elif [[ "$choice" == "2" ]]; then
        load_game
        break

    elif [[ "$choice" == "3" ]]; then
        ai_opponent=!$ai_opponent
    fi
done


while true; do
    while true; do
        clear
        print_board

        if $ai_opponent && [[ $player == $circle ]]; then
            play_computer
            free_spot_count=$((free_spot_count - 1))
        else
            echo -e "Gracz $(get_color $player), wybierz pole (0-8) | 9 - zapis"
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
        fi

        if win_check "${board[@]}"; then
            clear
            print_board
            echo -e "Gracz $(get_color $player) wygrywa"

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

        if [[ $player == $cross ]]; then
            player=$circle
        else
            player=$cross
        fi
    done

    init_board
    free_spot_count=9

    if [[ $starting_player == $cross ]]; then
        starting_player=$circle
    else
        starting_player=$cross
    fi

    player=$starting_player
done
