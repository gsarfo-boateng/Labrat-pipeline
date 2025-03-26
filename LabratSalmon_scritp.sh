#!/bin/bash

# Define necessary inputs
TXFASTA="/media/george/903d0d27-cc4e-4189-b0ae-1683a54b5cda/george/mel_3UTR/LABRAT-master/TFseqs.fasta"
THREADS=32

TRIMMED_DIR="."

# Initialize arrays to store the forward reads, reverse reads, and sample names
READS1=()
READS2=()
SAMPLES=()

# Loop through all *_1_trimmed.fastq.gz files in the ../trimmed/ folder
for R1_FILE in "$TRIMMED_DIR"/*_1_trimmed.fastq.gz; do
    # Extract the base sample name by removing the trailing _1_trimmed.fastq.gz
    SAMPLE_NAME=$(basename "$R1_FILE" _1_trimmed.fastq.gz)
    
    # Define the corresponding reverse read file (assumes naming follows *_2_trimmed.fastq.gz)
    R2_FILE="$TRIMMED_DIR/${SAMPLE_NAME}_2_trimmed.fastq.gz"
    
    # Check if the corresponding reverse read exists
    if [[ -f "$R2_FILE" ]]; then
        # Append the files and sample name to the arrays
        READS1+=("$R1_FILE")
        READS2+=("$R2_FILE")
        SAMPLES+=("$SAMPLE_NAME")
    else
        echo "Warning: Reverse read not found for $R1_FILE. Skipping sample $SAMPLE_NAME..."
    fi
done

# Convert the arrays into comma-separated strings
READS1_STR=$(IFS=,; echo "${READS1[*]}")
READS2_STR=$(IFS=,; echo "${READS2[*]}")
SAMPLES_STR=$(IFS=,; echo "${SAMPLES[*]}")

# Generate the LABRAT.py command in runSalmon mode
LABRAT_CMD="LABRAT.py --mode runSalmon --txfasta $TXFASTA \
--reads1 $READS1_STR \
--reads2 $READS2_STR \
--samplename $SAMPLES_STR \
--threads $THREADS"

# Print the generated command for review
echo "Generated LABRAT.py command:"
echo "$LABRAT_CMD"

# To execute the command, uncomment the following line:
eval "$LABRAT_CMD"
