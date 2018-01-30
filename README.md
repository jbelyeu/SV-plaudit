# SV-plaudit: A cloud-assisted framework manually curating thousands of structural variants

SV-plaudit provides a pipeline for creating image views of genomic intervals, automatically storing them in the cloud, deploying a website to view/score them, and retrieving scores for analysis.

The PlotCritic and Samplot submodules each contain instructions for use. `upload.py` is the meeting point between them and handles uploading images created by Samplot to cloud storage managed by PlotCritic.

Steps:
1. Generate a set of images with Samplot.
2. Follow PlotCritic setup instructions to create the cloud environment.
3. Use `upload.py` with the directory that holds the Samplot images to upload them.
    ```
    python upload.py -d your_directory
    ```
4. Follow PlotCritic instructions to score images and retrieve scores.

Python dependencies:
* numpy
* matplotlib
* pylab
* pysam
* statistics
* boto3
* yaml 

All of these are available from [pip](https://pypi.python.org/pypi/pip).

Generating images:

Samplot requires alignments in BAM or CRAM format as primary input (if you use CRAM, you'll also need a reference genome like one used the the 1000 Genomes Project (ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/technical/reference/human_g1k_v37.fasta.gz). Follow the usage examples below to format your commands.
## Usage Examples: 


### Basic use case
We're  using data from NA12878, NA12889, and NA12890 in the [1000 Genomes Project](http://www.internationalgenome.org/about). 

Let's say we have BAM files and want to see what the inversion in NA12878 at 2:89161083-89185670 looks like. 
The following command will create an image of that region:
```
python src/samplot.py -c chr2 -s 89161083 -e 89185670 -b \
Samplot/test/data/high_coverage/NA12878_S1.restricted_sv_regions.bam,test/data/high_coverage/NA12889_S1.restricted_sv_regions.bam,test/data/high_coverage/NA12890_S1.restricted_sv_regions.bam \
-o img/hi_2_89161083_89185670.png -n NA12878,NA12889,NA12890 -t INV
```

<img src="doc/imgs/hi_2_89161083_89185670.png">

### Basic use case with sampling
That took 1m23.766s to generate. To speed things up, we'll use the -d flag to set the sampling depth at 200 reads from the region we're interested in.
```
python src/samplot.py -c chr2 -s 89161083 -e 89185670 -b \
test/data/high_coverage/NA12878_S1.restricted_sv_regions.bam,test/data/high_coverage/NA12889_S1.restricted_sv_regions.bam,test/data/high_coverage/NA12890_S1.restricted_sv_regions.bam \
-o img/hi_2_89161083_89185670_200reads.png -n NA12878,NA12889,NA12890 -t INV -d 200
```
<img src="doc/imgs/hi_2_89161083_89185670_200reads.png">

Generated in 0m3.632s and it looks pretty good. Read sampling will only filter out 'normal' reads - splitters, discordants and read depth track will still appear.


### CRAM inputs
Samplot also support CRAM input, which requires a reference fasta file for reading as noted above.

```
python src/samplot.py -c 2 -s 89161083 -e 89185670 -b \
test/data/low_coverage/NA12878.mapped.ILLUMINA.bwa.CEU.low_coverage.restricted_sv_regions.20121211.cram,test/data/low_coverage/NA12889.mapped.ILLUMINA.bwa.CEU.low_coverage.restricted_sv_regions.20130415.cram,test/data/low_coverage/NA12890.mapped.ILLUMINA.bwa.CEU.low_coverage.restricted_sv_regions.20130415.cram \
-o img/low_2_89161083_89185670_200reads_cram.png -n NA12878,NA12889,NA12890 -t INV -d 200 -r ~/Research/data/reference/hg19/hg19.fa
```
<img src="doc/imgs/low_2_89161083_89185670_200reads_cram.png">

## Creating a PlotCritic website
Prep:

1. If you don't already have one, create an [AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html), then use it to make a dedicated [IAM user](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) with the following permissions:
   * IAMFullAccess
   * AmazonS3FullAccess
   * AmazonDynamoDBFullAccess
   * AmazonCognitoPowerUser
Take note of the Access Key ID and Secret Access Key created for your IAM User.

2. Clone PlotCritic repo, cd into it, and run the following command (substituting your own fields):
```
python plotcritic_setup.py \
	-p "PROJECT_NAME" \
	-e "YOUR_EMAIL" \
	-a "ACCESS_KEY_ID" \
	-s "SECRET_ACCESS_KEY"
```
You will receive an email with the URL for your new website, with a confirmation code to log in.

3. Upload images to S3. If using PlotCritic as part of the [SV-Plaudit](https://github.com/jbelyeu/SV-Plaudit) pipeline, refer to that repository for upload instructions.



## More Options
### Retrieval Script
The `retrieval.py` script retrieves data from the DynamoDB table and prints it out as tab-separated lines, allowing you to create custom reports.

Usage:
```
python retrieval.py 
```

The `-f` (filters) option allows you to pass in key-value pairs to filter the results. 
The following example shows only results from a project named "my_project":
```
python retrieval.py  -f "project","my_project"
```

### Delete Project
The `delete_project.py` script allows you to delete a project to clean up after finishing, using configuration information from the config.json file created during setup. 

Usage:
```
python delete_project.py 
```

If `-f` (full-deletion) option is not selected, you can choose to keep various resources, such as the S3 bucket containing your images and the DynamoDB tables with scoring results. If `-f` is selected, however, all external resources will be deleted permanently.
The following example deletes the entire project and all related resources:
```
python delete_project.py -f
```

### HTTPS
For additional security, use AWS Cloudfront to deploy with an SSL certificate through the Amazon Credential Manager (ACM). Further instructions available [here](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GettingStarted.html).
