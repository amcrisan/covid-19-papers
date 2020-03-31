## COVID-19 Research Paper Analysis

I have been exploring the kaggle dataset of COVID-19 research papers. I have tackled this challenge using a method for  for unsupervised topic clustering that I developed over a year ago and whose primary objective is to perform a rapid unsupervised topic clustering of data. The method requires not input from clusters beyond the articles they wish to cluster.

Details about Adjutant and how it works are available on github: https://github.com/amcrisan/Adjutant

To this algorithm, I have also been exploring automatic summarization of cluster content via bullet point summaries and ranking of articles according to their representativeness of the cluster. This repository contains these results.

## How to use these results

How reliable or valid are these results if I don’t have a ground truth dataset to compare them against? It’s always hard to say for certain. The algorithmic pipeline I’ve set up is not meant to give you the absolute ‘right’ answer, but to try give you something useful. Useful things in this case are signals in the data that are really loud and obvious, signals that are easily picked up by the algorithm.  You’ll note that there are many unclustered documents, those are instances were the signal is less clear. Instead of attempting to classify those articles, I have chosen to leave them alone - I am not sure what the right thing to do with them is. What remains is clear signal that algorithm is somewhat sure about, based upon its cascade of decisions and the assumptions made. It’s not perfect, I aim for it to be good enough. 

THe goal of this analysis is to give an individual a high level view of what is contained within this document corpus and to shed some light on some signals that compe through and that maybe be of use.

## Data Explainer

Two datasets here have the results of Adjutant's unßsupervised topic clustering,  as well as my additional experiments in content ranking and cluster summarization: **papers_with_cluster.csv** and **cluster_auto_summary.csv** 

### papers_with_clusters.csv

Adds additional columns to the metadata file that ships with the Kaggle competition dataset. Also modified the SHA so that some files that originally did not have an SHA now do (makes analysis a little bit easier). 
These are the columns that were added and their explanation:

* *tsneComp1* : the x-axis co-ordinate resulting from the tsne dimensionality reduced data
* *tsneComp2*: the y-axis co-ordinate resulting form the tsne dimensionality reduced data
* *tsneCluster* : a numeric value indicating the cluster that a particular document was assigned to. 0 means that the document was not assigned to any cluster.
* *tsneClusterStatus* : a boolean variable (TRUE/FALSE) indicating whether a document was part of a cluster (TRUE) or not (FALSE)
* *tsneClusterNames :* a name assigned to the cluster, it is essentially the top two most common stemmed (suffices chopped off) terms in the cluster. 
* *clustRank : *content based page rank probability (1  / higher is better)

You can use tsneComp1 and tsneComp2 to plot the data onto a scatter chart. You can also make up your own cluster name based upon some different critieria.

### cluster_auto_summary.csv

A pre-computed set of automatically generated summaries. This isn’t truly natural language generation, instead I stick a bunch of representative sentences together. This is a work in progress,

These are the columns of that table:

* *PMID : *a unique sentence ID (note to self : change this header, confusing, should be sentenceID)
* *tsneClusterNames :* a name assigned to the cluster, it is essentially the top two most common stemmed (suffices chopped off) terms in the cluster. 
* *sentence : *one of the top five sentences selected by the clustering summary code.
* *clustSummary :* a generated summary, which is a concatenation of the five sentences for the cluster


