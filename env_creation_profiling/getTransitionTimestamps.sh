#!/bin/bash

# this script should grep all EPN logs for the state transition timestamps.
# the output is written to a textfile in the following format:
# epn | task name | state (from) | state (to) | timestamp

# some development stuff
# [09:11:20][STATE] Starting FairMQ state machine --> IDLE
# [09:11:35][STATE] IDLE ---> INITIALIZING DEVICE
# [09:11:35][INFO] id00000000046eb4b0:Init            S> Entering Init callback.
# [09:11:35][INFO] id00000000046eb4b0:Init            E> Exiting Init callback.
# [09:11:35][STATE] INITIALIZING DEVICE ---> INITIALIZED
# [09:12:00][STATE] INITIALIZED ---> BINDING
# [09:12:00][STATE] BINDING ---> BOUND
# [09:12:00][STATE] BOUND ---> CONNECTING
# [09:12:00][STATE] CONNECTING ---> DEVICE READY
# [09:12:00][STATE] DEVICE READY ---> INITIALIZING TASK
# [09:12:00][INFO] id00000000046eb4b0:InitTask        S> Entering InitTask callback.
# [09:12:01][INFO] id00000000046eb4b0:InitTask        E> Exiting InitTask callback waiting for the remaining region callbacks.
# [09:12:01][INFO] id00000000046eb4b0:InitTask        S> Waiting for registation events.
# [09:12:01][INFO] id00000000046eb4b0:InitTask        *> Memory registration event received.
# [09:12:01][INFO] id00000000046eb4b0:InitTask        E> Done waiting for registration events.
# [09:12:01][STATE] INITIALIZING TASK ---> READY

states=(
  "Starting_FairMQ_state_machine"
  "IDLE"
  "INITIALIZING_DEVICE"
  "INITIALIZED"
  "BINDING"
  "DEVICE_READY"
  "INITIALIZING_TASK"
  "READY"
)
states_grep_strings=(
  "Starting FairMQ state machine \-\-> IDLE"
  "IDLE \-\-\-> INITIALIZING DEVICE"
  "INITIALIZING DEVICE \-\-\-> INITIALIZED"
  "INITIALIZED \-\-\-> BINDING"
  "DEVICE READY \-\-\-> INITIALIZING TASK"
  "INITIALIZING TASK \-\-\-> READY"
)

wDir=$(pwd)
outFile=$wDir/transition_timestamps.txt
[[ -f $outFile ]] && rm $outFile

# loop over states
for i in $(seq 1 $((${#states[@]} - 2))); do
  
  # state names
  state_from=${states[$((i - 1))]}
  state_to=${states[$i]}
  [[ $state_from == "BINDING" ]] && continue
  
  # loop over epn directories to obtain epn
  for dir in $wDir/epn*; do
    cd $dir
    epn=$(echo $dir | awk -F'/' '{print $NF}')

    # loop over *out.log files
    for file in $(ls *_reco*_out.log); do
      task=$(echo $file | awk -F'_2024' '{print $1}')

      # get timestamps in seconds
      timestamp=$(date --date="$(grep "${states_grep_strings[$((i - 1))]}" $file | awk '{print $1}' | sed -e 's/\]\[STATE\]//g' -e 's/\[//g')" +%H:%M:%S)

      #output
      printf "%-9s %-44s %-33s %-33s %-10s\n" $epn $task $state_from $state_to $timestamp >>${outFile}
    done

    cd $wDir

  done

done

outFileSorted=$(echo $outFile | sed 's/.txt/_sorted.txt/g')
sort --key=5 ${outFile} >${outFileSorted}
