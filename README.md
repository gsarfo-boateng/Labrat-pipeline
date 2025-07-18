# Labrat-pipeline. Please see here for details: https://github.com/TaliaferroLab/LABRAT 

First download the binary zip files from the LABRAT repository and install using 

python3 setup.py install
1. down the Drosophila_melanogaster.BDGP6.88.chr.gff3.db, Drosophila_melanogaster.BDGP6.88.chr.gff3 and Drosophila_melanogaster.BDGP6.genome.fa.gz from the LABRAT github page: https://github.com/TaliaferroLab/LABRAT

2. 
python3 /media/judy/george/mel_3UTR/LABRAT-master/LABRAT_dm6annotation1.py --mode makeTFfasta --gff /media/judy/george/mel_3UTR/LABRAT-master/annot/Drosophila_melanogaster.BDGP6.88.chr.gff3 --genomefasta Drosophila_melanogaster.BDGP6.genome.fa.gz --lasttwoexons --librarytype 3pseq


3. run the LABRATpsi calcuation:

Complete pipeline:

#!/bin/bash

# Define log file
LOGFILE="LABRAT_pipeline.log"
exec > >(tee -a "$LOGFILE") 2>&1  # Redirect output to both console and log file

echo "Starting LABRAT pipeline... $(date)"

# ========================
# STEP 1: Generate TF Fasta
# ========================
echo "Step 1: Generating transcript FASTA..."


python3 /media/judy/george/mel_3UTR/LABRAT-master/LABRAT_dm6annotation.py --mode makeTFfasta --gff /media/judy/george/mel_3UTR/LABRAT-master/annot/Drosophila_melanogaster.BDGP6.88.chr.gff3 --genomefasta Drosophila_melanogaster.BDGP6.genome.fa.gz \
--lasttwoexons --librarytype 3pseq

if [[ $? -ne 0 ]]; then
    echo "Error: makeTFfasta failed!"
    exit 1
fi
echo "TF Fasta generation complete."

# =======================
# STEP 2: Run Salmon
# =======================
echo "Step 2: Running Salmon for quantification..."

TXFASTA="/media/george/903d0d27-cc4e-4189-b0ae-1683a54b5cda/george/mel_3UTR/LABRAT-master/TFseqs.fasta"
THREADS=32
TRIMMED_DIR="."

READS1=()
READS2=()
SAMPLES=()

# Find paired-end reads
for R1_FILE in "$TRIMMED_DIR"/*_1_trimmed.fastq.gz; do
    SAMPLE_NAME=$(basename "$R1_FILE" _1_trimmed.fastq.gz)
    R2_FILE="$TRIMMED_DIR/${SAMPLE_NAME}_2_trimmed.fastq.gz"
    
    if [[ -f "$R2_FILE" ]]; then
        READS1+=("$R1_FILE")
        READS2+=("$R2_FILE")
        SAMPLES+=("$SAMPLE_NAME")
    else
        echo "Warning: Missing R2 for $SAMPLE_NAME, skipping..."
    fi
done

# Convert arrays to comma-separated strings
READS1_STR=$(IFS=,; echo "${READS1[*]}")
READS2_STR=$(IFS=,; echo "${READS2[*]}")
SAMPLES_STR=$(IFS=,; echo "${SAMPLES[*]}")

# Run Salmon
LABRAT_CMD="LABRAT.py --mode runSalmon --txfasta $TXFASTA \
--reads1 $READS1_STR \
--reads2 $READS2_STR \
--samplename $SAMPLES_STR \
--threads $THREADS"

echo "Running: $LABRAT_CMD"
eval "$LABRAT_CMD"

if [[ $? -ne 0 ]]; then
    echo "Error: runSalmon failed!"
    exit 1
fi
echo "Salmon quantification complete."

# =======================
# STEP 3: Calculate PSI
# =======================
echo "Step 3: Calculating PSI values..."

python3 ../LABRAT-master/LABRAT_dm6annotation1.py --mode calculatepsi \
--salmondir salmondir/ \
--sampconds sampconds \
--conditionA ETOH \
--conditionB Non \
--gff ../LABRAT-master/annot/Drosophila_melanogaster.BDGP6.88.chr.gff3 \
--librarytype 3pseq

if [[ $? -ne 0 ]]; then
    echo "Error: calculatepsi failed!"
    exit 1
fi

echo "PSI calculation complete."
echo "LABRAT pipeline finished successfully! $(date)"

############

python3 ../../LABRAT-master/LABRAT_dm6annotation1.py --mode calculatepsi --salmondir salmondir/ --sampconds sampconds --conditionA NR --conditionB ER --gff ../../LABRAT-master/annot/Drosophila_melanogaster.BDGP6.88.chr.gff3 --librarytype 3pseq

awk 'BEGIN{FS=OFS="\t"} NR>1 && $9 != "NA" && $9 < 0.05 {count++} END{print "Number of genes with FDR < 0.05:", count}' LABRAT.psis.pval


python3 ../../LABRAT-master/LABRAT_dm6annotation1.py --mode calculatepsi --salmondir salmondir/ --sampconds sampconds --conditionA NR --conditionB ER --gff ../../LABRAT-master/annot/Drosophila_melanogaster.BDGP6.88.chr.gff3 --librarytype 3pseq 


Condition A samples: FR109NR2, FR109NR3


Condition B samples: FR109ER2, FR109ER3


Condition A samples: FR112NNR1, FR112NNR2


Condition B samples: FR112NER1, FR112NER2


Condition A samples: FR113NNR2, FR113NNR3


Condition B samples: FR113NER2, FR113NER3



Condition A samples: ZI274NNR1, ZI274NNR2


Condition B samples: ZI274NER1, ZI274NER2


Condition A samples: ZI31NNR1, ZI31NNR3


Condition B samples: ZI31NER1, ZI31NER3


Condition A samples: ZI418NNR1, ZI418NNR2


Condition B samples: ZI418NER1, ZI418NER2
