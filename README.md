# SV-plaudit: A cloud-assisted framework manually curating thousands of structural variants

SV-plaudit provides a pipeline for creating image views of genomic intervals, automatically storing them in the cloud, deploying a website to view/score them, and retrieving scores for analysis.

The PlotCritic and Samplot submodules each contain instructions for use. `upload.py` handles uploading images created by Samplot to cloud storage managed by PlotCritic.

This repository should be cloned using the --recursive flag to include submodules:
```
git clone --recursive https://github.com/jbelyeu/SV-plaudit.git
```

**Steps for use (details below):**
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


## Usage 
### Step 1: Image Generation: 
Samplot requires alignments in BAM or CRAM format as primary input (if you use CRAM, you'll also need a reference genome like [this one](ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/technical/reference/human_g1k_v37.fasta.gz) from the the 1000 Genomes Project. The usage examples below use small BAM and CRAM files from the `samplot` repository.


#### Samplot basic use case
We're  using data from NA12878, NA12889, and NA12890 in the [1000 Genomes Project](http://www.internationalgenome.org/about). 

Let's say we have BAM files and want to see what the deletion in NA12878 at 4:115928726-115931880 looks like compared to the parents (NA12889, NA12890). 
The following command will create an image of that region:
```
python Samplot/src/samplot.py -n NA12878,NA12889,NA12890 -b Samplot/test/alignments/NA12878_restricted.bam,Samplot/test/alignments/NA12889_restricted.bam,Samplot/test/alignments/NA12890_restricted.bam -o 4_115928726_115931880.png -s 115928726 -e 115931880 -c chr4 -a -t DEL > 4_115928726_115931880.args
```

<img src="/doc/imgs/4_115928726_115931880.png">

#### CRAM inputs
Samplot also support CRAM input, which requires a reference fasta file for reading as noted above. Notice that the reference file is not included in this repository due to size.

```
python Samplot/src/samplot.py -n NA12878,NA12889,NA12890 -b Samplot/test/alignments/NA12878_restricted.cram,Samplot/test/alignments/NA12889_restricted.cram,Samplot/test/alignments/NA12890_restricted.cram -o cramX_101055330_101067156.png -s 101055330 -e 101067156 -c chrX -a -t DUP -r ~/Research/data/reference/hg19/hg19.fa > cram_X_101055330_101067156.args
```
<img src="doc/imgs/cramX_101055330_101067156.png">

### Step 2: Creating a PlotCritic website
If you don't already have one, create an [AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html), then use it to make a dedicated [IAM user](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console) with the following permissions:
   * AmazonS3FullAccess
   * AmazonDynamoDBFullAccess
   * AmazonCognitoPowerUser
   * Add the following IAM permissions policy:
```
{  
   "Version":"2012-10-17",
   "Statement":[  
      {  
         "Sid":"VisualEditor0",
         "Effect":"Allow",
         "Action":[  
            "iam:PassRole",
            "iam:CreateRole",
            "iam:AttachRolePolicy"
         ],
         "Resource":"*"
      }
   ]
}
```
   
Take note of the Access Key ID and Secret Access Key created for your IAM User.

Run the following command (substituting your own fields):
```
python PlotCritic/setup.py \
	-p "PROJECT_NAME" \
	-e "YOUR_EMAIL" \
	-a "ACCESS_KEY_ID" \
	-s "SECRET_ACCESS_KEY"
```
You will receive an email with the URL for your new website, with a confirmation code to log in. This script creates a configuration file `config.json` within the PlotCritic directory that later scripts require.


### Step 3: Upload images from samplot to PlotCritic website
Upload images to S3. Uses `config.json`, which was created by the `PlotCritic/setup.py` script.
```
python upload.py -d [your_directory] -c [config_file]
```
### Step 4: Score images
This section is still under development

### Step 5: Retrieve scores and analyze results

#### Retrieving scores
The `retrieval.py` script retrieves data from the DynamoDB table and prints it out as tab-separated lines, allowing you to create custom reports. Uses `config.json`. Results are stored in a tab-separated file.

Usage:
```
python retrieval.py -c [config_file] > retrieved_data.csv
```

The `-f` (filters) option allows you to pass in key-value pairs to filter the results. 
The following example shows only results from a project named "my_project":
```
python retrieval.py  -f "project","my_project" -c [config_file] > retrieved_data.csv
```

#### Annotate a VCF with the scoring results
The results of scoring can be added to a VCF file as annotations in the INFO field. This annotation requires the output file from score retrieval. The `config.json` file is not required.
```
python SV-plaudit/annotate.py -s retrieved_data.txt -v NA12878.trio.svt.vcf.gz -a new.vcf -o mean -n 1,0,1
```
Arguments used in this example are:

`-s` File of scoring results (input, from score retrieval step above).

`-v` VCF file of variants represented in the scoring experiment, to be annotated with scoring results (input).

`-a` Annotated VCF. Contains same fields as original VCF, but with annotations added for scored variants (output).

`-o` Operation argument. A function to apply to scores for generation of an overall curation score for the variant. Allowed functions are `mean`, `median`,  `min`, `max`.

`-n` Numeric representation of the answer options, in order (order based on `config.json` file). In the example above,  the curation answers are "Supports", "Does not support", "De novo". If 3 reviewers gave a variant the scores "Supports", "Does not support", "De novo", respectively, the curation score resulting would be the mean of 1,0,1 or .66.


### Additional options
#### Deleting a project
The `delete_project.py` script allows you to delete a project to clean up after finishing, using configuration information from the `config.json` file. 

Usage:
```
python delete_project.py -c [config_file]
```

If `-f` (full-deletion) option is not selected, you can choose to keep various resources, such as the S3 bucket containing your images and the DynamoDB tables with scoring results. If `-f` is selected, however, all external resources will be deleted permanently.
The following example deletes the entire project and all related resources:
```
python delete_project.py -f -c [config_file]
```

#### HTTPS
For additional security, use AWS Cloudfront to deploy with an SSL certificate through the Amazon Credential Manager (ACM). Further instructions available [here](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GettingStarted.html).
