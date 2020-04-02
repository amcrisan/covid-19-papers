#!/usr/bin/env Rscript
library(jsonlite)
library(adjutant)
library(dplyr)
library(ggplot2)

#adding sha for docs that don't have it, makes life way better, could introduc some replicates though.
dat<-read.csv(file="./data/all_sources_metadata_2020-03-13_Ana_Cleaned.csv",header=TRUE,stringsAsFactors = FALSE) %>%
  mutate(sha= ifelse(sha == "", paste(sample(c(letters,0:9),52,replace=TRUE),collapse =""), sha))

#files<- list.files(path = "./data/comm_use_subset/comm_use_subset/",full.names = TRUE)[1:500]
files<- c(list.files(path = "./data/comm_use_subset/comm_use_subset/",full.names = TRUE),
          list.files(path = "./data/noncomm_use_subset/noncomm_use_subset/",full.names = TRUE),
          list.files(path = "./data/biorxiv_medrxiv/biorxiv_medrxiv/",full.names=TRUE),
          list.files(path="./data/pmc_custom_license/pmc_custom_license/",full.names=TRUE))

files<-data.frame(sha = gsub(".json","",basename(files)),
                  path = files,
                  stringsAsFactors = FALSE)

# ---- after removing all the repeats ---
keep_files<- dat %>%
  filter(nchar(sha) == 40)

files<- filter(files,sha %in% keep_files[,"sha"])


# ---- grab the full text ----

res<-c()

#convert JSON to data frame

for(filePath in files$path){
  tmp<-read_json(filePath)
  
  metatmp<-dat[which(dat$sha == tmp$paper_id),]

  txt<-sapply(tmp$body_text,function(x){x$text})
  txt<- paste(sapply(tmp$body_text,function(x){x$text}),collapse = " " )
  abstract<-ifelse(length(tmp$list)==0, "", unlist(tmp$abstract[[1]]$text))
  
  txt<-paste(abstract,txt,collapse=" ")
  
  #Formatting for Adjutant
  risResults<-data.frame(PMID=tmp$paper_id,
                         YearPub=metatmp$publish_time,
                         Journal=as.character(metatmp$journal),
                         Authors=metatmp$authors,
                         Title=as.character(tmp$metadata$title),
                         Abstract=txt,
                         articleType = metatmp$abstract,
                         language = "eng",
                         pmcCitationCount = 0,
                         pmcID = metatmp$pmcid,
                         doi = metatmp$doi,
                         stringsAsFactors = FALSE)
  
  res<-rbind(res,risResults)
}

save.image("intermediateAnalysis2.Rda")

#include and format papers that don't have full text
no_txt<-dplyr::anti_join(dat, files, by="sha")

#formatting for Adjutant
no_txt_df<-data.frame(PMID=no_txt$sha,
                      YearPub=no_txt$publish_time,
                      Journal=no_txt$journal,
                      Authors=no_txt$authors,
                      Title=as.character(no_txt$title),
                      Abstract=as.character(no_txt$abstract),
                      articleType = as.character(no_txt$source_x),
                      language = "eng",
                      pmcCitationCount = 0,
                      pmcID = no_txt$pmcid,
                      doi = as.character(no_txt$doi),
                      stringsAsFactors = FALSE)

#Putting it all together
df <-full_join(res,no_txt_df) 

#remove those items that don't appear to have 

#tidy corpus              
tidy_df<-tidyCorpus(corpus = df,
                    stopTerms = c("author","copyright","funder","holder−preprin",
                                  "biorxiv", "copyright", "doi", "doi.org", "holder",
                                  "http","peer","preprint","review",
                                  "journal", "articl", "publi","includ", "studi",
                                  "cc-by-nc-nd","license","preprint","medrxiv","bioarxiv",
                                  "peer-reviewed"))

tsneObj<-runTSNE(tidy_df,check_duplicates=FALSE)

save.image("intermediateAnalysis.Rda")

#add t-SNE co-ordinates to df object
df<-inner_join(df,tsneObj$Y,by="PMID")
optClusters <- optimalParam(df)

df<-inner_join(df,optClusters$retItems,by="PMID") %>%
  mutate(tsneClusterStatus = ifelse(tsneCluster == 0, "not-clustered","clustered"))


clustNames<-df %>%
  group_by(tsneCluster)%>%
  mutate(tsneClusterNames = getTopTerms(clustPMID = PMID,
                                        clustValue=tsneCluster,topNVal = 2,tidyCorpus=tidy_df)) %>%
  mutate(tsneClusterNames = sapply(tsneClusterNames, function(x){
    y<-strsplit(x,split="-")[[1]]
    return(paste(y[1:2],collapse="-"))
    }))%>%
  select(PMID,tsneClusterNames) %>%
  ungroup()

#update document corpus with cluster names
df<-inner_join(df,clustNames,by=c("PMID","tsneCluster"))

clusterNames <- df %>%
  dplyr::group_by(tsneClusterNames) %>%
  dplyr::summarise(medX = median(tsneComp1),
                   medY = median(tsneComp2)) %>%
  dplyr::filter(tsneClusterNames != "Not-Clustered")

g<- ggplot(df,aes(x=tsneComp1,y=tsneComp2,group=tsneClusterNames))+
  geom_point(aes(colour = tsneClusterStatus),alpha=0.2)+
  stat_ellipse(aes(alpha=tsneClusterStatus))+
  geom_label(data=clusterNames,aes(x=medX,y=medY,label=tsneClusterNames),size=3,colour="red")+
  scale_colour_manual(values=c("black","blue"),name="cluster status")+
  scale_alpha_manual(values=c(1,0),name="cluster status")+ #remove the cluster for noise
  theme_bw()

save.image("intermediateAnalysis2.Rda")

ggsave("alldata.pdf",g,height=15,width = 15, units="in")

