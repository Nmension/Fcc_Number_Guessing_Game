#!/bin/bash
PSQL="psql -X --username=freecodecamp --dbname=number_guess -t --no-align -c"

MAIN_MENU() {
  #first message
  echo "Enter your username:"
  #wait for user input
  read NAME
  #query the users table to look for the inputted NAME and store result in a var
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE name='$NAME';")
  #if the var is empty, i.e the name doesn't exist in the DB 
  if [[ -z $USER_ID ]]
  then
    #print according message
    echo "Welcome, $NAME! It looks like this is your first time here."
    #insert new username
    INSERT_NEW_USERNAME=$($PSQL "INSERT INTO users(name) VALUES('$NAME');")
    #get new user id
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE name='$NAME';")
  else 
    #here, as the var isn't empty
    #vars that store queries for existing best_game and games_played info in the DB
    BEST_GAME=$($PSQL "SELECT MIN(nb_of_guesses) FROM games INNER JOIN users USING(user_id) WHERE name='$NAME';")
    GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games INNER JOIN users USING(user_id) WHERE name='$NAME';")
    #print another message using existing DB info
    echo "Welcome back, $NAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  fi
  #call the other function
  GAME
}

GAME () {
  #rand n stored in a var
  SECRET_NUMBER=$(( RANDOM % 1001 ))
  #var for number of tries with a default value of 1
  ATTEMPTS=1
  #print the first message of the started game
  echo -e "\nGuess the secret number between 1 and 1000:"
  #loop that doesn't stop until the secret number is guessed
  until [[ $GUESS == $SECRET_NUMBER ]]
  do
    #read user input
    read GUESS
    #check if input is a number
    if [[ $GUESS =~ ^[0-9]+$ ]]
    then
      #if inputted numb is greater than rand n
      if [[ $GUESS -gt $SECRET_NUMBER ]]
      then
        #print hint message
        echo "It's lower than that, guess again:"
        #increment the var for the numb of tries
        (( ATTEMPTS++ ))
      #elif input if lower than rand n
      elif [[ $GUESS -lt $SECRET_NUMBER ]]
      then
        #print other hint message
        echo "It's higher than that, guess again:"
        #increment the var of the numb of tries
        (( ATTEMPTS++ ))
      fi
    else #if input is not a number
      #print try-again message
      echo "That is not an integer, guess again:"
    fi
  done
  #print congratulation messagge
  echo "You guessed it in $ATTEMPTS tries. The secret number was $SECRET_NUMBER. Nice job!"
  #game insertion into the DB
  INSERT_GAME=$($PSQL "INSERT INTO games(user_id, nb_of_guesses) VALUES($USER_ID, $ATTEMPTS);")
  #var for the new number of guesses
  NEW_BEST_GAME=$($PSQL "SELECT MIN(nb_of_guesses) FROM games INNER JOIN users USING(user_id) WHERE name='$NAME';")
  #var the new number of games played by that user
  NEW_GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games INNER JOIN users USING(user_id) WHERE name='$NAME';")
  #UPDATE DB with the new info
  UPDATE_USER_INFO=$($PSQL "INSERT INTO users(name, games_played, best_game) VALUES('$NAME', $NEW_GAMES_PLAYED, $NEW_BEST_GAME) ON CONFLICT(name) DO UPDATE SET games_played = EXCLUDED.games_played, best_game = EXCLUDED.best_game;")
}
MAIN_MENU
