### Please see here for details: https://github.com/TaliaferroLab/LABRAT 

First download the binary zip files from the LABRAT repository and install using 

python3 setup.py install
1. download the Drosophila_melanogaster.BDGP6.88.chr.gff3.db, Drosophila_melanogaster.BDGP6.88.chr.gff3 and Drosophila_melanogaster.BDGP6.genome.fa.gz from the LABRAT github page: https://github.com/TaliaferroLab/LABRAT

2. 
python3 /media/judy/george/mel_3UTR/LABRAT-master/LABRAT_dm6annotation1.py --mode makeTFfasta --gff /media/judy/george/mel_3UTR/LABRAT-master/annot/Drosophila_melanogaster.BDGP6.88.chr.gff3 --genomefasta Drosophila_melanogaster.BDGP6.genome.fa.gz --lasttwoexons --librarytype 3pseq


3. run the LABRATpsi calcuation:

python3 ../../LABRAT-master/LABRAT_dm6annotation1.py --mode calculatepsi --salmondir salmondir/ --sampconds sampconds --conditionA NR --conditionB ER --gff ../../LABRAT-master/annot/Drosophila_melanogaster.BDGP6.88.chr.gff3 --librarytype 3pseq


### check the number of significant genes
awk 'BEGIN{FS=OFS="\t"} NR>1 && $9 != "NA" && $9 < 0.05 {count++} END{print "Number of genes with FDR < 0.05:", count}' LABRAT.psis.pval


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
