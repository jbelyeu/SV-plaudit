# SV-plaudit: A cloud-assisted framework manually curating thousands of structural variants
*(Please cite https://doi.org/10.1093/gigascience/giy064)*

SV-plaudit provides a pipeline for creating image views of genomic intervals, automatically storing them in the cloud, deploying a website to view/score them, and retrieving scores for analysis. SV-plaudit supports image generation sequencing data from BAM or CRAM files from Illumina paired-end sequencing, PacBio or Oxford Nanopore Technologies long-read sequencing, or 10X Genomics linked-read sequencing.

This README contains detailed instructions for many of the different options supported by the SV-plaudit framework, including a submodule that contains much of the functionality; [PlotCritic](https://github.com/jbelyeu/PlotCritic). **Links to instructional videos at bottom of page.**


This repository should be cloned using the --recursive flag to include PlotCritic:
```
git clone --recursive https://github.com/jbelyeu/SV-plaudit.git
```

**Steps for use (details below):**
1. Install dependencies
2. Generate a set of images with [samplot](https://github.com/jbelyeu/samplot).
2. Follow PlotCritic setup instructions to create the cloud environment.
3. Upload the images to PlotCritic website.
4. Score images.
5. Retrieve scores and analyze results.

## Usage 
### Step 1: Install dependencies
Install [conda](https://docs.conda.io/en/latest/), then run this command in the main SV-plaudit directory: `conda install -y -c bioconda --file requirements.txt`.
This will install samplot, a tool for creating the SV plots SV-plaudit needs, as well as other dependencies.

### Step 2: Image Generation: 
Refer to the [samplot](https://github.com/jbelyeu/samplot) project for image generation instructions. For all image-generation commands with either the `samplot plot` or `samplot vcf`, use the special flag `-a`, which will output an additional metadata file based on the arguments to this call. The file will be in .json format and will have the same name as the output file specified by -o except for the extension .json

### Step 2: Creating a PlotCritic website
Refer to the [PlotCritic](https://github.com/jbelyeu/PlotCritic) project for step-by-step Website Deployment instructions.

### Step 3: Upload images to PlotCritic website

Upload images to S3. Uses `config.json`, which was created by the `PlotCritic/project_setup.py` script.
```
python PlotCritic/upload.py -d [your_directory] -c [config_file]
```
### Step 4: Score images
PlotCritic setup will send an email containing a link to the new site and a temporary access code to the email address you entered when you ran `project_setup.py` (at times this email can delay a few minutes, as it waits for the new website to go live). Click on the link and go to the `Manage Account` page, where you will need to enter that email address as username and the temporary access code as password. Click on the button labeled `Confirming new account`, then click `Submit` to proceed. You will be prompted to set your password; it is essential that you do so immediately or you will lose access. Click `Change password` when the page loads and enter your new password.

Notice that the `Manage Account` page is also the place to add additional users. Enter their email addresses and they will be sent an email like you received, with a temporary access code.

Now you're ready to score variants! We recommend watching [this video](https://www.youtube.com/watch?v=ono8kHMKxDs), which has an introduction to SV scoring with SV-plaudit.

### Step 5: Retrieve scores and analyze results

#### Retrieving scores
The `retrieval.py` script retrieves data from the DynamoDB table and prints it out as tab-separated lines, allowing you to create custom reports. Uses `config.json`. Results are stored in a tab-separated file.

Usage:
```
python PlotCritic/retrieval.py -c [config_file] > retrieved_data.csv
```

The `-f` (filters) option allows you to pass in key-value pairs to filter the results. 
The following example shows only results scored by a user with the email address "me@email.com":
```
python PlotCritic/retrieval.py  -f "email","me@email.com" -c PlotCritic/config.json > retrieved_data.csv
```

#### Annotate a VCF with the scoring results
The results of scoring can be added to a VCF file as annotations in the INFO field. This annotation requires the output file from score retrieval. The `config.json` file is not required. This requires that the `samplot_vcf.sh` script is used for generation of the images (or at least that the file naming convention of `samplot_vcf.sh`, 'SVTYPE_CHROM_POS-END.png', is maintained, as in 'DEL_22_37143105-37144405.png').
```
python annotate.py -s retrieved_data.csv -v Samplot/test/data/NA12878.trio.svt.subset.vcf -a new.vcf -o mean -n 1,0,1
```
Arguments used in this example are:

`-s` File of scoring results (input, from score retrieval step above).

`-v` VCF file of variants represented in the scoring experiment, to be annotated with scoring results (input).

`-a` Annotated VCF. Contains same fields as original VCF, but with annotations added for scored variants (output).

`-o` Operation argument. A function to apply to scores for generation of an overall curation score for the variant. Allowed functions are `mean`, `median`,  `min`, `max`.

`-n` Numeric representation of the answer options, in order (order based on `config.json` file). In the example above,  the curation answers are "Supports", "Does not support", "De novo". If 3 reviewers gave a variant the scores "Supports", "Does not support", "De novo", respectively, the curation score resulting would be the mean of 1,0,1 or .66.


### Additional options
#### Deleting a project
The `delete_project.py` script allows you to delete a project to clean up after finishing, using configuration information from the `config.json` file. Be aware that deleting external resources may take some time, so if you delete a project and then attempt to recreate it immediately you may get a resource error from AWS. If this occurs, you'll need to rerun deletion to remove any parts of the infrastructure that were created before failure, wait a bit, and then rerun project_setup.

Usage:
```
python PlotCritic/delete_project.py -c [config_file]
```

If `-f` (full-deletion) option is not selected, you can choose to keep various resources, such as the S3 bucket containing your images and the DynamoDB tables with scoring results. If `-f` is selected, however, all external resources will be deleted permanently.
The following example deletes the entire project and all related resources:
```
python PlotCritic/delete_project.py -f -c [config_file]
```

#### HTTPS
For additional security, use AWS Cloudfront to deploy with an SSL certificate through the Amazon Credential Manager (ACM). Further instructions available [here](http://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/GettingStarted.html).


**Instructional Video: SV-plaudit Basics**

<a href="http://www.youtube.com/watch?feature=player_embedded&v=ono8kHMKxDs" target="_blank"><img src="http://img.youtube.com/vi/ono8kHMKxDs/0.jpg" 
alt="SV-Plaudit Basics" width="240" height="180" border="10" /></a>

**Instructional Video: Detailed How-To**

<a href="http://www.youtube.com/watch?feature=player_embedded&v=phD-GdkOwiY" target="_blank"><img src="http://img.youtube.com/vi/phD-GdkOwiY/0.jpg" 
alt="SV-Plaudit Basics" width="240" height="180" border="10" /></a>
