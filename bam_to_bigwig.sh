#!/bin/bash

#SBATCH --cpus-per-task=1
#SBATCH --ntasks=4
#SBATCH --time=10000:00
#SBATCH --mem=32000mb

# Set paths
REF_PFX="/media/judy/george/m6a/dm6.fasta"
CHROM_SIZES="/media/judy/george/m6a/dm6.chrom.sizes"

# Create necessary directories
mkdir -p pycra/mapped/bed/bw pycra/catfasta

# Process all *_1_trimmed.fastq.gz files
for R1_FILE in *_1_trimmed.fastq.gz; do
    # Extract the base name
    n=${R1_FILE%_1_trimmed.fastq.gz}
    R2_FILE="${n}_2_trimmed.fastq.gz"

    # Check if the corresponding R2 file exists
    if [[ ! -f "$R2_FILE" ]]; then
        echo "Paired file $R2_FILE not found for $R1_FILE. Skipping..."
        continue
    fi

    echo "Processing pair: $R1_FILE and $R2_FILE"

    # Reverse complement R1 reads
    seqkit seq -r -p "$R1_FILE" > "${n}_R1_001_trimmed.fastq"

    # Unzip R2 reads
    gunzip "$R2_FILE"

    # Remove PCR duplicates
    pyFastqDuplicateRemover.py -f "${n}_R1_001_trimmed.fastq" -o pycra/"${n}_1.fasta"
    pyFastqDuplicateRemover.py -f "${n}_2_trimmed.fastq" -o pycra/"${n}_2.fasta"

    # Combine FASTA files
    cat pycra/"${n}_1.fasta" pycra/"${n}_2.fasta" > pycra/catfasta/"${n}_R1R2.fasta"

    # Prepare read group and map reads with BWA MEM
    READ_GRP="$n"
    RG="@RG\tID:$n\tPL:ILLUMINA\tSM:$READ_GRP\tDS:pfx=$REF_PFX"

    bwa mem -M -R "$RG" "$REF_PFX" pycra/catfasta/"${n}_R1R2.fasta" > pycra/mapped/"$n.sam"

    # Convert SAM to BAM and sort
    samtools view -bS pycra/mapped/"$n.sam" -o pycra/mapped/"$n.bam"
    rm pycra/mapped/"$n.sam"
    samtools sort pycra/mapped/"$n.bam" -o pycra/mapped/"$n.sorted.bam"
    samtools index pycra/mapped/"$n.sorted.bam"

    # Separate strands
    samtools view -F 16 -b -o pycra/mapped/bed/"$n.plus.bam" pycra/mapped/"$n.sorted.bam"
    samtools view -f 16 -b -o pycra/mapped/bed/"$n.minus.bam" pycra/mapped/"$n.sorted.bam"

    # Calculate and scale BedGraph for plus strand
    total_reads_plus=$(samtools view -c pycra/mapped/bed/"$n.plus.bam")
    scale_plus=$(echo "scale=6; $total_reads_plus/1000000" | bc)
    bedtools genomecov -ibam pycra/mapped/bed/"$n.plus.bam" -bg -scale "$scale_plus" > pycra/mapped/bed/"$n.plus.bedgraph"

    # Calculate and scale BedGraph for minus strand
    total_reads_minus=$(samtools view -c pycra/mapped/bed/"$n.minus.bam")
    scale_minus=$(echo "scale=6; $total_reads_minus/1000000" | bc)
    bedtools genomecov -ibam pycra/mapped/bed/"$n.minus.bam" -bg -scale "$scale_minus" > pycra/mapped/bed/"$n.minus.bedgraph"

    # Sort BedGraph files
    sort -k1,1 -k2,2n pycra/mapped/bed/"$n.plus.bedgraph" > pycra/mapped/bed/"$n.plus.sorted.bedgraph"
    sort -k1,1 -k2,2n pycra/mapped/bed/"$n.minus.bedgraph" > pycra/mapped/bed/"$n.minus.sorted.bedgraph"

    # Convert minus BedGraph to negative values
    awk '{ $4 *= -1 } 1' pycra/mapped/bed/"$n.minus.sorted.bedgraph" > pycra/mapped/bed/"$n.minus.sorted_converted.bedgraph"

    # Convert BedGraph to BigWig
    bedGraphToBigWig pycra/mapped/bed/"$n.plus.sorted.bedgraph" "$CHROM_SIZES" pycra/mapped/bed/bw/"$n.plus.bw"
    bedGraphToBigWig pycra/mapped/bed/"$n.minus.sorted_converted.bedgraph" "$CHROM_SIZES" pycra/mapped/bed/bw/"$n.minus.bw"

    # Cleanup intermediate files
    rm pycra/mapped/bed/"$n.plus.bedgraph"
    rm pycra/mapped/bed/"$n.minus.bedgraph"
    rm pycra/mapped/bed/"$n.minus.sorted.bedgraph"
    rm pycra/mapped/"$n.bam"

    # Gzip the original trimmed fastq files
    gzip "${n}_R1_001_trimmed.fastq" "${n}_2_trimmed.fastq"

    echo "Processing completed for $n"
done

echo "All samples processed successfully!"
