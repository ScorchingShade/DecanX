#!/bin/bash

####################################################
# This is an automation script to run at beginning #
####################################################

#### EMAIL FOR REPORT #########
EMAIL='ankushors789@gmail.com'
###############################

###### Colors ##########

#tput setab [1-7] # Set the background colour using ANSI escape
#tput setaf [1-7] # Set the foreground colour using ANSI escape

# Num  Colour    #define         R G B
#
# 0    black     COLOR_BLACK     0,0,0
# 1    red       COLOR_RED       1,0,0
# 2    green     COLOR_GREEN     0,1,0
# 3    yellow    COLOR_YELLOW    1,1,0
# 4    blue      COLOR_BLUE      0,0,1
# 5    magenta   COLOR_MAGENTA   1,0,1
# 6    cyan      COLOR_CYAN      0,1,1
# 7    white     COLOR_WHITE     1,1,1

black=`tput setaf 0`
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`

blackB=`tput setab 0`
redB=`tput setab 1`
greenB=`tput setab 2`
yellowB=`tput setab 3`
blueB=`tput setab 4`
magentaB=`tput setab 5`
cyanB=`tput setab 6`
whiteB=`tput setab 7`

reset=`tput sgr0`

########## Variables ###########

DIR_LIST=`ls`
LOAD_AVG=`uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d,` 
HEALTH_STATUS=`uptime | awk -F'load average:' '{ print $2 }' | cut -f1 -d, | awk '{if ($1 > 2) print "Unhealthy"; else if ($1 > 1) print "Caution"; else print "Normal"}'`


######### System Vars ##########
# hostname = `hostname`
# kernal_ver = `uname -r`
# uptime = `uptime | sed 's/.*up \([^,]*\), .*/\1/'`
# last_reboot = `who -b | awk '{print $3,$4}'`



progress_bar()
{
  local DURATION=$1
  local INT=0.25      # refresh interval

  local TIME=0
  local CURLEN=0
  local SECS=0
  local FRACTION=0

  local FB=2588       # full block

  trap "echo -e $(tput cnorm); trap - SIGINT; return" SIGINT

  echo -ne "$(tput civis)\r$(tput el)│"                # clean line

  local START=$( date +%s%N )

  while [ $SECS -lt $DURATION ]; do
    local COLS=$( tput cols )

    # main bar
    local L=$( bc -l <<< "( ( $COLS - 5 ) * $TIME  ) / ($DURATION-$INT)" | awk '{ printf "%f", $0 }' )
    local N=$( bc -l <<< $L                                              | awk '{ printf "%d", $0 }' )

    [ $FRACTION -ne 0 ] && echo -ne "$( tput cub 1 )"  # erase partial block

    if [ $N -gt $CURLEN ]; then
      for i in $( seq 1 $(( N - CURLEN )) ); do
        echo -ne \\u$FB
      done
      CURLEN=$N
    fi

    # partial block adjustment
    FRACTION=$( bc -l <<< "( $L - $N ) * 8" | awk '{ printf "%.0f", $0 }' )

    if [ $FRACTION -ne 0 ]; then
      local PB=$( printf %x $(( 0x258F - FRACTION + 1 )) )
      echo -ne \\u$PB
    fi

    # percentage progress
    local PROGRESS=$( bc -l <<< "( 100 * $TIME ) / ($DURATION-$INT)" | awk '{ printf "%.0f", $0 }' )
    echo -ne "$( tput sc )"                            # save pos
    echo -ne "\r$( tput cuf $(( COLS - 6 )) )"         # move cur
    echo -ne "│ $PROGRESS%"
    echo -ne "$( tput rc )"                            # restore pos

    TIME=$( bc -l <<< "$TIME + $INT" | awk '{ printf "%f", $0 }' )
    SECS=$( bc -l <<<  $TIME         | awk '{ printf "%d", $0 }' )

    # take into account loop execution time
    local END=$( date +%s%N )
    local DELTA=$( bc -l <<< "$INT - ( $END - $START )/1000000000" \
                   | awk '{ if ( $0 > 0 ) printf "%f", $0; else print "0" }' )
    sleep $DELTA
    START=$( date +%s%N )
  done

  echo $(tput cnorm)
  trap - SIGINT
}


progress_bar 1


############## DIR Check #########
dir_check()
{
  echo "${greenB} ${black} Program Loaded${reset}"
  echo "Checking available files"
  echo "$DIR_LIST "
  echo " ${greenB} ${black} Test Passed ${reset}"
}

cpu_health_check(){
  MPSTAT=`which mpstat`
  MPSTAT=$?
  if [ $MPSTAT != 0 ]
  then
    echo "Please install mpstat!"
    echo "On Debian based systems:"
    echo "sudo apt-get install sysstat"
    echo "On RHEL based systems:"
    echo "yum install sysstat"
  else
    echo -e "mpstat available"  

    LSCPU=`which lscpu`

    LSCPU=$?

    if [ $LSCPU != 0 ]
    then  
      RESULT=$RESULT" lscpu required to procedure accurate results"
    else  
      cpus=`lscpu | grep -e "^CPU(s):" | cut -f2 -d: | awk '{print $1}'`

      i=0

      while [ $i -lt $cpus ]
      do
        echo "CPU$i : `mpstat -P ALL | awk -v var=$i '{ if ($3 == var ) print $4 }' `"  
        let i=$i+1
      done
    fi    

  fi

    

  echo 'Load average is '$LOAD_AVG
  echo 'Health status is '$HEALTH_STATUS

  echo " ${greenB} ${black} Test Passed ${reset}"
}

process(){
  PROCESS_LIST=`ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 5`
  TOP_PROCESS=`top b -n1 | head -17 | tail -11`

  echo 
  echo "${yellowB} ${black} Processes running${reset}"
  echo "$PROCESS_LIST"
  echo
  echo "${yellowB} ${black} Top Processes${reset}"
  echo "$TOP_PROCESS"
  echo
  echo " ${greenB} ${black} Test Passed ${reset}"
}

disk_usage(){
  echo

  DISK_USE=`df -Pkh | grep -v 'Filesystem' > /tmp/df.status`
  echo 'Running disk process' $DISK_USE
  progress_bar 1

  echo
  while read DISK
    do
      LINE=`echo $DISK | awk '{print $1,"\t",$6,"\t",$5," used","\t",$4," free space"}'`
      echo -e $LINE
      echo
    done < /tmp/df.status

  echo -e "

    Heath Status"

  echo  


  while read DISK

    do

      USAGE=`echo $DISK | awk '{print $5}' | cut -f1 -d%`

      if [ $USAGE -ge 95 ]

      then

        STATUS='Unhealthy'

      elif [ $USAGE -ge 90 ]

      then

        STATUS='Caution'

      else

        STATUS='Normal'

      fi

      LINE=`echo $DISK | awk '{print $1,"\t",$6}'`

      #here we print result with status
      echo -ne $LINE "\t\t" $STATUS

      echo

    done < /tmp/df.status

  `rm /tmp/df.status`
  echo
  echo " ${greenB} ${black} Test Passed ${reset}"


}

memory(){
  TOTALMEM=`free -m | head -2 | tail -1| awk '{print $2}'`
  USEDMEM=`free -m | head -2 | tail -1| awk '{print $3}'`
  FREEMEM=`free -m | head -2 | tail -1| awk '{print $4}'`

  TOTALSWAP=`free -m | tail -1| awk '{print $2}'`
  USEDSWAP=`free -m | tail -1| awk '{print $3}'`
  FREESWAP=`free -m | tail -1| awk '{print $4}'`

  echo
  echo 'Total Memory Available' $TOTALMEM
  echo 'Used Memory ' $USEDMEM
  echo 'Free Memory' $FREEMEM
  echo
  echo 'Total Swap Memory' $TOTALSWAP
  echo 'Used Swap Memory' $USEDSWAP
  echo 'Free Swap Memory' $FREESWAP

  
}

report_gen(){
FILENAME="health-`hostname`-`date +%y%m%d`-`date +%H%M`.txt"
dir_check>$FILENAME
process>>$FILENAME
cpu_health_check>>$FILENAME
disk_usage>>$FILENAME
memory>>$FILENAME

echo -e "${greenB} ${black} Reported file $FILENAME generated in current directory. ${reset}" $RESULT

# if [ "$EMAIL" != '' ]
#   then  
#     STATUS=`which mail`
#   if [ "$?" != 0 ]
#     then
#       echo "The program 'mail' is currently not installed."
#     else
#       `cat $FILENAME | mail -s "$FILENAME" $EMAIL`
#   fi
# fi      

}

#dir_check
#cpu_health_check
#process
#disk_usage
#memory

report_gen

