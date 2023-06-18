#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"
echo -e "\n~~~~~ MY SALON ~~~~~\n"

MAIN () {
    
    if [[ $1 ]]
    then
        echo -e "$1\n"
    fi

    echo -e "Welcome to My Salon, these are the services that we offer:\n"
    echo "$($PSQL "SELECT * FROM services")" | while IFS=" | " read service_id service_name
    do
        echo "$service_id) $service_name"
    done

    echo -e "\nChoose a service ID to book the service"
    read SERVICE_ID_SELECTED
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
        MAIN "Please enter a valid service id"
    fi

    SERVICE_SELECTED=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")

    if [[ -z $SERVICE_SELECTED ]]
    then
        MAIN "Please enter a valid service id"
    fi
: '
if u don't use if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]], u get:
Choose a service ID to book the service
badinput
ERROR:  column "badinput" does not exist
LINE 1: SELECT name FROM services WHERE service_id=badinput
                                                   ^
Please enter a valid service id

instead of:
Choose a service ID to book the service
5
Please enter a valid service id
'

    echo -e "\nWhat's your phone number?"
    read CUSTOMER_PHONE

    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")

    if [[ -z $CUSTOMER_NAME ]]
    then
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME
        INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME')") 
    fi
    BOOK_APPOINTMENT
}

BOOK_APPOINTMENT () {
    echo -e "\nAt What time should I book your $SERVICE_SELECTED appointment, $CUSTOMER_NAME?"
    read SERVICE_TIME

    CUSTOMER_NAME_FORMATTED=$(echo $CUSTOMER_NAME | sed 's/ //')
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE name='$CUSTOMER_NAME_FORMATTED'")

    INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(name, customer_id, service_id, time) VALUES('$CUSTOMER_NAME_FORMATTED', $CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
    echo -e "\nI have put you down for a $SERVICE_SELECTED at $SERVICE_TIME, $CUSTOMER_NAME."
}

MAIN 

: '
    why do we need the CUSTOMER_NAME_FORMATTED variable?
    cuz when `if [[ -z $CUSTOMER_NAME ]]` code block and BOOK_APPOINTMENT function runs, theres no problem
    BUT
    when if block is skipped and only BOOK_APPOINTMENT function runs, this error is thrown:
    - ERROR:  syntax error at or near ","
    - LINE 1: ..., customer_id, service_id, time) VALUES(' akshat', , 1, '1am'...
    why?
    cuz CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE name='$CUSTOMER_NAME'")
    translates to: SELECT customer_id FROM customers WHERE name=' akshat' (if the phone no. passed earlier was 555-555)
    ' akshat' DNE. 'akshat' exists, hence CUSTOMER_ID=NULL, hence the error

    For some reason, this error is not thrown when u input a new phone no.
'
