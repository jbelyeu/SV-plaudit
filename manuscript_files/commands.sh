#set up SV-plaudit and create a curation website from high-coverage sequence data
git clone --recursive https://github.com/jbelyeu/SV-plaudit.git
cd SV-plaudit
wget ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/phase3/data/NA12892/high_coverage_alignment/NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam -O NA12892.bam
wget ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/phase3/data/NA12891/high_coverage_alignment/NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam -O NA12891.bam
wget ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/phase3/data/NA12878/high_coverage_alignment/NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam -O NA12878.bam
samtools index NA12878.bam
samtools index NA12891.bam
samtools index NA12892.bam
bcftools view -c 1 -s NA12878 ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/phase3/integrated_sv_map/ALL.wgs.integrated_sv_map_v2.20130502.svs.genotypes.vcf.gz > NA12878.vcf
mkdir sv_imgs
Samplot/src/samplot_vcf.sh -S Samplot/src/samplot.py -o sv_imgs -v NA12878.vcf NA12878.bam NA12891.bam NA12892.bam
python PlotCritic/setup.py -p NA12878_trio -e ryan@layerlab.org -a YOUR_AWS_ACCESS_KEY_ID -s "YOUR_AWS_SECRET_ACCESS_KEY"
python upload.py -d sv_imgs -c PlotCritic/config.json


#to recreate figures from manuscript:
#download regions from high-coverage BAM files
samtools view -b ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/data/NA12878/NIST_NA12878_HG001_HiSeq_300x/RMNISTHS_30xdownsample.bam 6:66009228-69049033 > NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_66009228_69049033.bam 13:65637801-65638216 > NA12878_giab_med_13_65637801_65638216.bam

samtools view -b ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12878/high_coverage_alignment/NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam 6:66009228-69049033 > NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_66009228_69049033.bam
samtools view -b ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12878/high_coverage_alignment/NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam 10:102635396-152638414 > NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_10_102635396_152638414.bam
samtools view -b ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12878/high_coverage_alignment/NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam 11:4072926-6973837 > NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_11_4072926_6973837.bam

samtools view -b ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12891/high_coverage_alignment/NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam 6:66009228-69049033 > NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_66009228_69049033.bam
samtools view -b ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12891/high_coverage_alignment/NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam 10:102635396-152638414 > NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_10_102635396_152638414.bam
samtools view -b ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12891/high_coverage_alignment/NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam 11:4072926-6973837 > NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_11_4072926_6973837.bam

samtools view -b ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12892/high_coverage_alignment/NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam 6:66009228-69049033 > NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_66009228_69049033.bam
samtools view -b ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12892/high_coverage_alignment/NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam 10:102635396-152638414 > NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_10_102635396_152638414.bam
samtools view -b ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/phase3/data/NA12892/high_coverage_alignment/NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906.bam 11:4072926-6973837 > NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_11_4072926_6973837.bam

#index downloaded regions
samtools index NA12878_giab_med_13_65637801_65638216.bam

samtools index NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_10_*.bam
samtools index NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_11_*.bam
samtools index NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_*.bam

samtools index NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_10_*.bam
samtools index NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_11_*.bam
samtools index NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_*.bam

samtools index NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_10_*.bam
samtools index NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_11_*.bam
samtools index NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_*.bam#make plots of specific regions (Fig. 1)

#make plots of different coverage (Fig. 1)
python samplot/src/samplot.py -c 6 -s 67009228 -e 67049033 -t DEL -o fig1/DEL_6_67009228_67049033.pdf -n "NA12878","NA12891","NA12892" -b NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_66009228_69049033.bam,NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_66009228_69049033.bam,NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_6_66009228_69049033.bam
python samplot/src/samplot.py -c 10 -s 132635396 -e 132638414 -t DEL -o fig1/DEL_10_132635396_132638414.pdf -n "NA12878","NA12891","NA12892" -b NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_10_132635396_132638414.bam,NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_10_132635396_132638414.bam,NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_10_132635396_132638414.bam
python samplot/src/samplot.py -c 11 -s 4972926 -e 4973837 -t DEL -o fig1/DEL_11_4972926_4973837.pdf -n "NA12878","NA12891","NA12892" -b NA12878.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_11_4972926_4973837.bam,NA12891.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_11_4972926_4973837.bam,NA12892.mapped.ILLUMINA.bwa.CEU.high_coverage_pcr_free.20130906_11_4972926_4973837.bam

#make plots of different variant types (Supplementary Fig. 1)
python samplot/src/samplot.py -c 10 -s 90795115 -e 90800286 -t DUP -o other_types/DUP_10_90795115_90800286.pdf -n "Duplication" -b NA12878.bam
python samplot/src/samplot.py -c 12 -s 12544792 -e 12546607 -t INV -o other_types/INV_12_12544792_12546607.pdf -n "Inversion" -b NA12878.bam

#make plots of different coverage (Supplementary Fig. 2)
python samplot/src/samplot.py -c 13 -s 65637801 -e 65638216 -t DEL -o hi_coverage/DEL_13_65637801-65638216_hi.pdf -n "High Coverage" -b NA12878.bam 
python samplot/src/samplot.py -c 13 -s 65637801 -e 65638216 -t DEL -o med_coverage/DEL_13_65637801-65638216_med.pdf -n "Medium Coverage" -b NA12878_giab_med_13_65637801_65638216.bam
python samplot/src/samplot.py -c 13 -s 65637801 -e 65638216 -t DEL -o low_coverage/DEL_13_65637801-65638216_low.pdf -n "Low Coverage" -b /scratch/local/u6000294/sv-plaudit/NA12878.mapped.ILLUMINA.bwa.CEU.low_coverage.20121211.bam
