#!/bin/bash

# Define log file
LOGFILE="LABRAT_calculatepsi.log"

# Extract sample names from sampconds file
ETOH_SAMPLES=($(awk '$2 ~ /^ETOH/' sampconds))
NON_SAMPLES=($(awk '$2 ~ /^Non/' sampconds))

# Create a dictionary-like structure (associative array in bash)
declare -A SAMPLE_PAIRS

# Populate ETOH samples in the array
for SAMPLE in "${ETOH_SAMPLES[@]}"; do
    BASE_NAME=$(echo "$SAMPLE" | sed 's/^ETOH_//')
    SAMPLE_PAIRS["$BASE_NAME"]="$SAMPLE"
done

# Run LABRAT for each matched pair
for SAMPLE in "${NON_SAMPLES[@]}"; do
    BASE_NAME=$(echo "$SAMPLE" | sed 's/^Non_//')

    if [[ -n "${SAMPLE_PAIRS[$BASE_NAME]}" ]]; then
        CONDITION_A="${SAMPLE_PAIRS[$BASE_NAME]}"
        CONDITION_B="$SAMPLE"

        # Define LABRAT command for this sample pair
        LABRAT_CMD="python3 ../LABRAT-master/LABRAT_dm6annotation1.py --mode calculatepsi \
        --salmondir salmondir/ \
        --sampconds sampconds \
        --conditionA $CONDITION_A \
        --conditionB $CONDITION_B \
        --gff ../LABRAT-master/annot/Drosophila_melanogaster.BDGP6.88.chr.gff3 \
        --librarytype 3pseq"

        # Log and run the command
        echo "Running LABRAT for: $CONDITION_A vs $CONDITION_B" | tee -a "$LOGFILE"
        echo "$LABRAT_CMD" | tee -a "$LOGFILE"
        eval "$LABRAT_CMD" >> "$LOGFILE" 2>&1
        echo "LABRAT execution for $CONDITION_A vs $CONDITION_B completed." | tee -a "$LOGFILE"
    else
        echo "WARNING: No matching ETOH sample for $SAMPLE" | tee -a "$LOGFILE"
    fi
done

echo "All PSI calculations completed. Check $LOGFILE for details." | tee -a "$LOGFILE"
