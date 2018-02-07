#! /usr/bin/env python
from __future__ import print_function
# Python 2/3 compatibility
import sys
import argparse
import os
#import datetime
import cyvcf2
import statistics

def comma_list(in_str):
   return list(filter(None ,in_str.split(',')))

parser = argparse.ArgumentParser(description="creates an annotated variant file (vcf) with the results from PlotCritic scoring")
parser.add_argument("-s", "--scores", help="file of results from PlotCritic scoring",required=True)
parser.add_argument("-v", "--vcf", help="variant file to annotate",required=True)
parser.add_argument("-a", "--annotated_outfile", help="name for new annotated variant file",required=True)
parser.add_argument("-o", "--operation", help="summarizing operation for scores. " + 
        "Options are mean, median, standard deviation (stdev), mode, max, min",
        required=False, choices=["mean", "median", "stdev", "mode", "max", "min"])
parser.add_argument("-n", "--number_map", help="ordered list of number values for answers, used for summarizing results."+
        " Required if --operation is included. Example: if the curation answers in order are: 'yes', 'no', 'maybe' => 1,0,0.5 ", 
        type=comma_list, required=False)
args = parser.parse_args()
if args.operation and not args.number_map:
    parser.print_help()
    sys.exit(0)
scored_variants = {}
question = ""
score_fields = {"scorer_count":0}
answers = []
with open(args.scores, 'r') as scores:
    for line in scores:
        if line[0] == "#":
            line = line.strip().strip("#")
            if line[0] == "Q":
                question = line[2:]
            elif line[0] == "A":
                answers = line[2:].split("\t")
                for answer in answers:
                    score_fields[answer] = 0
        else:
            if args.number_map and len(answers) != len(args.number_map):
                print ("Error: count of curation answers does not equal count of number values in number_map")
                print ("Curation answers: " + ", ".join(answers))
                parser.print_help()
                sys.exit(0)
            fields = line.split("\t")
            key = os.path.splitext(os.path.basename(fields[2]))[0]
            if key not in scored_variants:
                scored_variants[key] = {'email':{}}
            email = fields[1]
            if email not in scored_variants[key]['email']:
                scored_variants[key]['email'][email] = []
            score = fields[3]
            #response_time = datetime.datetime.fromtimestamp(int(fields[5]))
            scored_variants[key]['email'][email].append([score, int(fields[5])])

for key in scored_variants:
    scored_variants[key]["score_fields"] = dict(score_fields)
    
    for email in scored_variants[key]['email']:
        #latest_timestamp = datetime.datetime.min
        latest_timestamp = 0
        answer = ''
        #find latest answer for each user
        for entry in scored_variants[key]['email'][email]:
            if entry[1] > latest_timestamp:
                answer = entry[0]
                latest_timestamp = entry[1]
        scored_variants[key]['score_fields'][answer] += 1
        scored_variants[key]['score_fields']['scorer_count'] += 1

vcf = cyvcf2.VCF(os.path.expanduser(args.vcf))
vcf.add_info_to_header({"ID": "SVPD", "Description": "Details of SV-plaudit scorer count and scores in the format COUNT|SCORE1,SCORE2,SCOREN. Answers the question: `" + question + "` Available answers were as follows: `" + "`; `".join(answers) + "`", "Type":'Character', 'Number':'1'})
vcf.add_info_to_header({"ID": "SVP", "Description": "SV-plaudit curation score, the " + args.operation + " of scores for that entry where the values of the following curation answers: `" +  "`; `".join(answers) + "` are " + ",".join(args.number_map), "Type":'Float',  'Number':'1'})
writer = cyvcf2.Writer(args.annotated_outfile, vcf)

for variant in vcf:
    if variant.INFO.get('END'):
        key = variant.INFO.get('SVTYPE') + '_' + \
                variant.CHROM + '_' + \
                str(variant.POS) + '-' + \
                str(variant.INFO.get('END'))
        if key in scored_variants:
            vcf_annotation = str(scored_variants[key]['score_fields']['scorer_count']) + "|"
            for answer in answers:
                vcf_annotation += str(scored_variants[key]['score_fields'][answer]) + ","
            vcf_annotation = vcf_annotation[:-1]
            if args.operation:
                score_counts = vcf_annotation.split("|")[1].split(",")
                score_values = []
                for i in range (len(score_counts)):
                    score_values += [float(args.number_map[i])] * int(score_counts[i])
                curation_score = 0
                try:
                    if args.operation == "max" or args.operation == "min":
                        curation_score = eval(args.operation)(score_values)
                    else:
                        curation_score = getattr(statistics,args.operation)(score_values)
                except:
                    print ("Warning: failed to perform specified operation on entry:")
                    print (variant)
                    continue
                variant.INFO['SVP'] = str(curation_score)
            variant.INFO['SVPD'] = vcf_annotation
        writer.write_record(variant)
writer.close()
