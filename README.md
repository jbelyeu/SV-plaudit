# SV-plaudit: A cloud-assisted framework manually curating thousands of structural variants

SV-plaudit provides a pipeline for creating image views of genomic intervals, automatically storing them in the cloud, deploying a website to view/score them, and retrieving scores for analysis.

The PlotCritic and Samplot submodules each contain instructions for use. `upload.py` is the meeting point between them and handles uploading images created by Samplot to cloud storage managed by PlotCritic.

**General Steps:**
1. Generate a set of images with Samplot.
2. Follow PlotCritic setup instructions to create the cloud environment.
3. Upload the images to PlotCritic website.
4. Score images.
5. Retrieve scores and analyze results.

**Python dependencies:**
* numpy
* matplotlib
* pylab
* pysam
* statistics
* boto3
* yaml 

All of the above are available from [pip](https://pypi.python.org/pypi/pip).

Generating images:

Samplot requires alignments in BAM or CRAM format as primary input (if you use CRAM, you'll also need a reference genome like [this one](ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/technical/reference/human_g1k_v37.fasta.gz) from the the 1000 Genomes Project. Follow the usage examples below to format your commands.
## Image Generation Examples: 


### Basic use case
We're  using data from NA12878, NA12889, and NA12890 in the [1000 Genomes Project](http://www.internationalgenome.org/about). 

Let's say we have BAM files and want to see what the deletion in NA12878 at 4:115928726-115931880 looks like compared to the parents (NA12889, NA12890). 
The following command will create an image of that region:
```
python Samplot/src/samplot.py -n NA12878,NA12889,NA12890 -b Samplot/test/data/alignments/NA12878_restricted.bam,Samplot/test/data/alignments/NA12889_restricted.bam,Samplot/test/data/alignments/NA12890_restricted.bam -o 4_115928726_115931880.png -s 115928726 -e 115931880 -c chr4 -a -t DEL > 4_115928726_115931880.args
```

<img src="/doc/imgs/4_115928726_115931880.png">

### CRAM inputs
Samplot also support CRAM input, which requires a reference fasta file for reading as noted above. Notice that the reference file is not included in this repository due to size.

```
python Samplot/src/samplot.py -n NA12878,NA12889,NA12890 -b Samplot/test/data/alignments/NA12878_restricted.cram,Samplot/test/data/alignments/NA12889_restricted.cram,Samplot/test/data/alignments/NA12890_restricted.cram -o cramX_101055330_101067156.png -s 101055330 -e 101067156 -c chrX -a -t DUP -r ~/Research/data/reference/hg19/hg19.fa > cram_X_101055330_101067156.args
```
<img src="doc/imgs/cramX_101055330_101067156.png">

## Creating a PlotCritic website
Prep:

1. If you don't already have one, create an [AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html), then use it to make a dedicated [IAM user](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) with the following permissions:
   * IAMFullAccess
   * AmazonS3FullAccess
   * AmazonDynamoDBFullAccess
   * AmazonCognitoPowerUser
Take note of the Access Key ID and Secret Access Key created for your IAM User.

2. Run the following command (substituting your own fields):
```
python PlotCritic/plotcritic_setup.py \
	-p "PROJECT_NAME" \
	-e "YOUR_EMAIL" \
	-a "ACCESS_KEY_ID" \
	-s "SECRET_ACCESS_KEY"
```
You will receive an email with the URL for your new website, with a confirmation code to log in. This script creates a configuration file `config.json` within the PlotCritic directory that later scripts require.

3. Upload images to S3. Uses `config.json`.
```
python upload.py -d [your_directory]
```

4. Retrieve scores.
The `retrieval.py` script retrieves data from the DynamoDB table and prints it out as tab-separated lines, allowing you to create custom reports. Uses `config.json`.

Usage:
```
python retrieval.py 
```

The `-f` (filters) option allows you to pass in key-value pairs to filter the results. 
The following example shows only results from a project named "my_project":
```
python retrieval.py  -f "project","my_project"
```


## More options
### Annotate a VCF with the scoring results
The results of scoring can be added to a VCF file as annotations in the INFO field. This annotation requires the output file from score retrieval and accesses the `config.json` file.
```
python annotate.py -s retrieved_data.txt -v NA12878.trio.svt.vcf.gz -o new.vcf
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
