# SV-plaudit: A cloud-assisted framework manually curating thousands of structural variants
*(Please cite https://doi.org/10.1093/gigascience/giy064)*

__Important note:__ _We now recommend using the [PlotCritic](https://github.com/jbelyeu/PlotCritic) and [Samplot](https://github.com/ryanlayer/samplot) packages instead of the SV-plaudit module. These incorporate the utilities available from SV-plaudit and have been updated for improved usability and flexibility._

## Usage
SV-plaudit provides a pipeline for creating image views of genomic intervals, automatically storing them in the cloud, deploying a website to view/score them, and retrieving scores for analysis. SV-plaudit supports image generation sequencing data from BAM or CRAM files from Illumina paired-end sequencing, PacBio or Oxford Nanopore Technologies long-read sequencing, or 10X Genomics linked-read sequencing.

This README contains detailed instructions for many of the different options supported by the SV-plaudit framework, including Samplot and the PlotCritic submodule that contain most of the functionality; [samplot](https://github.com/ryanlayer/samplot) and [PlotCritic](https://github.com/jbelyeu/PlotCritic). **Links to instructional videos at bottom of page.**


This repository should be cloned using the --recursive flag to include PlotCritic:
```
git clone --recursive https://github.com/jbelyeu/SV-plaudit.git
```

**Overview of steps for use (details below):**
1. Generate a set of images with samplot.
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
Instructions for image generation with Samplot are available in the Samplot [readme](https://github.com/ryanlayer/samplot), with additional details in the [wiki](https://github.com/jbelyeu/samplot/wiki). It is essential that you use Samplot's `-a` parameter to create metadata files for PlotCritic (using either the `samplot plot` or `samplot vcf` command). If that is omitted accidentally, you can rerun the samplot command with the `-j` parameter to generate those metadata files. For more details, see the Samplot readme, wiki, and help (with `-h`).

### Step 2: Creating a PlotCritic website
If you don't already have one, create an [AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html).

The following instructions give detailed help on creating the IAM User, accurate as of February 2018. AWS at times updates the Console UI, so if we're behind in updating these instructions at any time refer to AWS resources for help ([IAM Policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create.html), [IAM user](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console)).

Create a new IAM Policy by opening the [IAM console](https://console.aws.amazon.com/iam/home#/home), selecting 'Policies' from the left side navigation bar, and then clicking 'Create Policy'. Switch to the JSON editor window and paste in the following Policy definition:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole",
                "iam:CreateRole",
                "iam:AttachRolePolicy",
                "iam:ListAttachedRolePolicies",
                "iam:DetachRolePolicy",
                "iam:DeleteRole"
            ],
            "Resource": "*"
        }
    ]
}
```
Click 'Review Policy', add a name (Ex. 'PlotCritic__Policy'), optionally a description, then click 'Create policy'.

Select 'Users' from the left navigation bar, then 'Add user'. Add a name for the user (Ex. 'PlotCritic_User'), click the radio button for 'Programmatic access', then 'Next: Permissions'. 

Choose 'Attach existing policies directly' and select the following policies:
   * AmazonS3FullAccess
   * AmazonDynamoDBFullAccess
   * AmazonCognitoPowerUser
   * Your new policy (Ex. 'PlotCritic__Policy')
   
Click 'Create user' and take note of the Access Key ID and Secret Access Key created for your IAM User. The Secret Access Key will not be available later, so you must record it at this point. 

Run the following command (substituting your own fields):
```
python PlotCritic/project_setup.py -p temp -e jrbelyeu@gmail.com \
    -a [ACCESS_KEY] -s [SECRET_ACCESS_ID] \
    -q "Does evidence in the sample support the variant called?" \
    -A "s":"Supports" "n":"Does not support" "d":"De novo" -r \
    -R "chrom" "start" "end" "sv_type" "titles" "bams" \
    -S "chrom" "start" "end" "sv_type"
```

The arguments used above are:

`-p` A project name (must be unique)

`-e` The email address of the user managing the project. You must be able to access this email account to use the website

`-a` The access key ID generated when you created your AWS user

`-s` The secret access key generated when you creates your AWS user

`-q` A curation question to display in the website for scoring images

`-A` The curation answers to display in the website for scoring images (must follow the example above, with a one-letter code and an answer for each entry, separated with commas and separated from other entries with spaces)

`-r` Flag to randomize the display order of images in the PlotCritic website on reload. If ommitted images display in the same order each time

'R' Metadata fields for downstream analysis of the scoring results (if not selected, defaults to a set of fields matching those used by samplot)

'S' Summary metadata fields to show in the web-based report page. Must also be in the report fields (-R)


If the curation question and answers are not set, defaults are as follows:
```
Question:
"Does the top sample support the variant type shown? If so, does it appear to be a de novo mutation? Choose one answer from below or type the corresponding letter key."

Answers:
"s","Supports" "n","Does not support" "d","De novo"
```

You will receive an email with the URL for your new website, with a confirmation code to log in. This script creates a configuration file `config.json` within the PlotCritic directory that later scripts require.

### Step 3: Upload images to PlotCritic website

Upload images to S3. Uses `config.json`, which was created by the `PlotCritic/project_setup.py` script.
```
python PlotCritic/upload.py -d [your_directory] -c [config_file]
```
### Step 4: Score images
This section is still under development

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
The results of scoring can be added to a VCF file as annotations in the INFO field. This annotation requires the output file from score retrieval. The `config.json` file is not required. This requires that the `samplot vcf` command is used for generation of the images (or at least that the same file naming convention, 'SVTYPE_CHROM_POS-END.png', is maintained, as in 'DEL_22_37143105-37144405.png').
```
python annotate.py -s retrieved_data.csv -v NA12878.trio.svt.subset.vcf -a new.vcf -o mean -n 1,0,1
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
