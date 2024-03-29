#!/bin/bash

# THIS SCRIPT IS DEVELOPED BY OZAN YUCEL | github.com/ozanyucell

function menu() { # main menu
    CHOICE=$(dialog --menu "Welcome $USER" 12 45 25 1 "Enter dairy for today, $DATE." 2 "Enter a diary for another date." 3 "View an old diary." 4 "Exit."\
        3>&1 1>&2 2>&3 3>&- ) # with this line, we are redirecting the output from stderr to stdout, https://stackoverflow.com/questions/29222633/bash-dialog-input-in-a-variable
    clear # clears the current box after it's done
}

function sub_menu() { # sub menu with yesno dialog
    $(dialog --yesno "$TEXT" 10 30\
        3>&1 1>&2 2>&3 3>&- )

    yesno=$? # takes output into a variable
    clear # clears the current box after it's done
}

# --passwordbox <text> <height> <width> <init>
function passwordbox() {  # a password box for taking password inputs
    PASSWORD=$(dialog --passwordbox "Password" 10 20\
        3>&1 1>&2 2>&3 3>&- )
    clear # clears the current box after it's done
}

# --calendar <text> <height> <width> <day> <month> <year>
function calendar() { # a calendar box for taking date inputs
    UNFORMATTED_DATE=$(dialog --calendar "Calendar" 5 50 "$(date +%d)" "$(date +%m)" "$(date +%Y)"\
        3>&1 1>&2 2>&3 3>&- )
    clear # clears the current box after it's done

    # now we need to check if the user selected a future date,
    # if so we will pop out a warning for the user,
    # we didn't want to block the user, 
    # in case if they want to leave a note for future
    CURRENT_DATE="$(date +%d)/$(date +%m)/$(date +%Y)"
    # lines below split inputs with given delimeter
    IFS='/' # DELIMETER
    read -ra IN_DATE_ARR <<< "$UNFORMATTED_DATE"
    read -ra CUR_DATE_ARR <<< "$CURRENT_DATE"

    # using 1 and 0 for future condition
    # 1 = True
    # 0 = False
    FUTURE=0

    # the code block belove checks if the given date is future from today
    if (( ${IN_DATE_ARR[2]} > ${CUR_DATE_ARR[2]} )); then
        FUTURE=1

    elif (( ${IN_DATE_ARR[2]} == ${CUR_DATE_ARR[2]} )); then

        if (( ${IN_DATE_ARR[1]} > ${CUR_DATE_ARR[1]} )); then
            FUTURE=1

        elif (( ${IN_DATE_ARR[1]} == ${CUR_DATE_ARR[1]} )); then

            if (( ${IN_DATE_ARR[0]} > ${CUR_DATE_ARR[0]} )); then
                FUTURE=1
            fi
        fi
    fi

    # the line below converts the form of date,
    # from dd/mm/yyyy to dd-mm-yyyy,
    # to avoid collision with file path form
    DATE=$(echo "$UNFORMATTED_DATE" | sed s/"\/"/"-"/g)
}

# --msgbox <text> <height> <width>
function messagebox() { # a message box for displaying text
    dialog --msgbox "$TEXT" 15 30
    clear # clears the current box after it's done
}

# --inputbox <text> <height> <width> <init>
function inputbox() { # an input box for taking diary inputs
    DIARY_INPUT=$(dialog --inputbox "Diary for $DATE" 30 50 "$OLD_INPUT" \
        3>&1 1>&2 2>&3 3>&- )
    clear # clears the current box after it's done
}

# zips and locks the diary with given password
function file_to_zip() {
    zip -P "$PASSWORD" "$FILE_NAME.zip" "$FILE_NAME.diary"
}

# unzips and unlocks the diary with given password
function zip_to_file() {
    unzip -P "$PASSWORD" "$ZIP_PATH" 2> error.txt # here redirecting the stderr into a file called error.txt, in case user enters a wrong password

    WRONG=$(grep -c "incorrect password$" error.txt) # making sure that the error output is for incorrect password

    rm error.txt # removing the error file after it's done
}

### RUN STARTS HERE ###

# creating a hidden directory for depositing diary inputs
mkdir "$HOME/.diary/"

# saving the current working directory into a varible and changing the current directory to script's directory
# because when I try to give a path into zip command, it zips the whole path, not only the file
cdw=$(pdw)

# we will be using this cdw variable just before the exit option
cd "$HOME/.diary/"

# infinite loop until user selects exit
while true
do
    DATE="$(date +%d)-$(date +%m)-$(date +%Y)" # current date
    OLD_INPUT="" # setting old input variable to empty for reseting the variable on every loop
    menu
    
    # Enter diary for current date
    if (( CHOICE == 1 )); then

        FILE_NAME="$(date +%d)-$(date +%m)-$(date +%Y)-$USER"

        # what if user tries to crate a diary for twice at the same day? we are letting him/her to edit it
        if [ -e "$FILE_NAME.zip" ]; then # if a diary input exists then:
            TEXT="You already have written diary for $DATE. Do you want to edit it?"
            sub_menu

            if (( yesno == 1 )); then # if user selects no, return to main menu
                continue
            else # if user selects yes, continue
                passwordbox
                ZIP_PATH="$HOME/.diary/$DATE-$USER.zip"
                zip_to_file

                if (( WRONG == 1 )); then # if password is wrong, display "Wrong password!" and return to main menu
                    TEXT="Wrong password!"
                    messagebox
                    continue
                fi

                # for editing the old diary
                FILE_PATH="$HOME/.diary/$DATE-$USER.diary"
                OLD_INPUT=$(cat "$FILE_PATH")
                inputbox
                passwordbox

                echo "$DIARY_INPUT" > "$FILE_NAME.diary"

                # converts file into zip with password
                file_to_zip

                # remove the unsecured file
                rm "$FILE_PATH"

                # for going back to menu
                continue
            fi
        fi

        # IF DIARY DOESN'T EXIST:
        # takes password and input into variables here
        inputbox
        passwordbox

        echo "$DIARY_INPUT" > "$FILE_NAME.diary"

        # converts file into zip with password
        file_to_zip

        # deletes the unprotected diary file
        rm "$FILE_NAME.diary"

    # enter a diary for another date
    elif (( CHOICE == 2 )); then
        calendar
        FILE_NAME="$DATE-$USER"

        # the code block below informs the user that he/she has selected a future date
        if (( FUTURE == 1 )); then
            TEXT="You have selected a future date. Are you sure that you want to proceed?"
            sub_menu
            if (( yesno == 1 )); then
                continue
            fi
        fi

        if [ -e "$FILE_NAME.zip" ]; then # if a diary input exists then:
            TEXT="You already have written diary for $DATE. Do you want to edit it?"
            sub_menu

            if (( yesno == 1 )); then # if user selects no, return to main menu
                continue
            else
                passwordbox
                ZIP_PATH="$HOME/.diary/$DATE-$USER.zip"
                zip_to_file

                if (( WRONG == 1 )); then # if password is wrong, display "Wrong password!" and return to main menu
                    TEXT="Wrong password!"
                    messagebox
                    continue
                fi

                # for editing the old diary
                FILE_PATH="$HOME/.diary/$DATE-$USER.diary"
                OLD_INPUT=$(cat "$FILE_PATH")
                inputbox
                passwordbox

                echo "$DIARY_INPUT" > "$FILE_NAME.diary"

                # converts file into zip with password
                file_to_zip

                # remove the unsecured file
                rm "$FILE_PATH"

                # for going back to menu
                continue
            fi
        fi

        # takes password and input into variables here
        inputbox
        passwordbox

        echo "$DIARY_INPUT" > "$FILE_NAME.diary"

        # converts file into zip with password
        file_to_zip

        # deletes the unprotected diary file
        rm "$FILE_NAME.diary"

    # view an old diary
    elif (( CHOICE == 3 )); then
        # pick date and password
        calendar

        # the code block below informs the user that he/she has selected a future date
        if (( FUTURE == 1 )); then
            TEXT="You have selected a future date. Are you sure that you want to proceed?"
            sub_menu
            if (( yesno == 1 )); then
                continue
            fi
        fi

        ZIP_PATH="$HOME/.diary/$DATE-$USER.zip"

        if [ -e "$ZIP_PATH" ]; then # if a diary input exists then:
            passwordbox

            # unlock zip with the password taken and extract
            zip_to_file

            if (( WRONG == 1 )); then # if password is wrong, display "Wrong password!" and return to main menu
                TEXT="Wrong password!"
                messagebox
                continue
            fi

            # save the content into a variable
            FILE_PATH="$HOME/.diary/$DATE-$USER.diary"
            TEXT=$(cat "$FILE_PATH")

            # print content to screen
            messagebox

            # remove unsecured file
            rm "$FILE_PATH"

        else # if a diary input doesn't exist
            TEXT="Diary for given date doesn't exist."
            messagebox
        fi

    # exit
    elif (( CHOICE == 4 )); then
        cd "$cdw" 
        exit # exit the script
    fi
done
