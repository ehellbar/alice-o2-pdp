#!/bin/bash

# this script should grep all EPN logs for the state transitions and calculate the transition times from the log timestamps.
# the output is written to a textfile in the following format:
# epn | task name | state (from) | state (to) | time for transition = timestamp(state) - timestamp(previous state)

# some development stuff
# cd ~/env_creation_profiling/dev_grep_logs_2rPGtuzQb8Y
# grep -nr '\-\-> ' | grep -v 'RUNNING ---> READY' | grep epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log
# output:
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:39:[11:24:18][STATE] Starting FairMQ state machine --> IDLE
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:40:[11:24:41][STATE] IDLE ---> INITIALIZING DEVICE
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:56:[11:25:02][STATE] INITIALIZING DEVICE ---> INITIALIZED
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:57:[11:25:06][STATE] INITIALIZED ---> BINDING
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:58:[11:25:06][STATE] BINDING ---> BOUND
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:59:[11:25:07][STATE] BOUND ---> CONNECTING
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:60:[11:25:07][STATE] CONNECTING ---> DEVICE READY
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:61:[11:25:07][STATE] DEVICE READY ---> INITIALIZING TASK
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:62:[11:25:17][STATE] INITIALIZING TASK ---> READY
# epn315/gpu-reconstruction_t0_reco1_2024-12-04-11-24-05_17991936139808813176_out.log:63:[11:25:32][STATE] READY ---> RUNNING

states=(
  "Starting FairMQ state machine"
  "IDLE"
  "INITIALIZING_DEVICE"
  "INITIALIZED"
  "DEVICE_READY"
  "INITIALIZING_TASK"
)
states_grep_strings=(
  "Starting FairMQ state machine \-\-> IDLE"
  "IDLE \-\-\-> INITIALIZING DEVICE"
  "INITIALIZING DEVICE \-\-\-> INITIALIZED"
  "CONNECTING \-\-\-> DEVICE READY"
  "DEVICE READY \-\-\-> INITIALIZING TASK"
  "INITIALIZING TASK \-\-\-> READY"
)

wDir=$(pwd)
outFile=$wDir/transition_times.txt
[[ -f $outFile ]] && rm $outFile

# loop over epn directories to obtain epn
for dir in $wDir/epn*; do
  cd $dir
  epn=$(echo $dir | awk -F'/' '{print $NF}')

  # loop over *out.log files
  for file in $(ls *_reco*_out.log); do
    task=$(echo $file | awk -F'_2024' '{print $1}')

    # loop over states
    for i in $(seq 1 $((${#states[@]} - 1))); do
      # state names
      state_from=${states[$((i - 1))]}
      state_to=${states[$i]}

      # get timestamps in seconds
      timestamp_from=$(date --date="$(grep "${states_grep_strings[$((i - 1))]}" $file | awk '{print $1}' | sed -e 's/\]\[STATE\]//g' -e 's/\[//g')" +%s)
      timestamp_to=$(date --date="$(grep "${states_grep_strings[$i]}" $file | awk '{print $1}' | sed -e 's/\]\[STATE\]//g' -e 's/\[//g')" +%s)

      # calculate transition times
      delta=$((timestamp_to - timestamp_from))

      #output
      printf "%-9s %-44s %-33s %-33s %-10s\n" $epn $task $state_from $state_to $delta >>${outFile}
    done

  done

  cd $wDir

done

outFileSorted=$(echo $outFile | sed 's/.txt/_sorted.txt/g')
sort -r --key=5 -h ${outFile} >${outFileSorted}
