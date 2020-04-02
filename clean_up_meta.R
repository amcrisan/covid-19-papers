#adding sha for docs that don't have it, makes life way better, could introduc some replicates though.
dat<-read.csv(file="./data/all_sources_metadata_2020-03-13.csv",header=TRUE,stringsAsFactors = FALSE)

#remove articles with no abstracts or full text, just not immediately useful.
# ----- articles that match files ------
files<- c(list.files(path = "./data/comm_use_subset/comm_use_subset/",full.names = FALSE),
          list.files(path = "./data/noncomm_use_subset/noncomm_use_subset/",full.names = FALSE),
          list.files(path = "./data/biorxiv_medrxiv/biorxiv_medrxiv/",full.names=FALSE),
          list.files(path="./data/pmc_custom_license/pmc_custom_license/",full.names=FALSE))

files<-gsub(".json","",files)
file_match<-match(files,dat$sha)

dat_files<-dat[file_match,] 

dat_files_pmcid<- dat_files %>%
  filter(pmcid !="") %>%
  group_by(pmcid) %>%
  sample_n(1)

dat_files_nopmcid<- dat_files %>%
  filter(pmcid =="") %>%
  group_by(doi) %>% #a mostly safe action
  sample_n(1)
  

# ----- articles without files ------
pmid_filt<-dat %>%
  anti_join(dat_files,by="sha") %>%
  filter(abstract != "" ) %>% #need to abstract at least to be useful
  filter(pmcid !="") %>%
  filter(!(pmcid %in% dat_files_pmcid$pmcid)) %>% #for some reason, this is a thing
  group_by(pmcid) %>%
  sample_n(1)

pmid_filt_nopmcid<-dat %>%
  anti_join(dat_files,by="sha") %>%
  filter(abstract != "" ) %>%
  filter(pmcid =="") %>%
  group_by(abstract) %>%
  sample_n(1)

# ---- Might not be totally cleaned but has removed some obvious things --- 
tmp<-full_join(dat_files_pmcid,dat_files_nopmcid) %>%
  full_join(pmid_filt)%>%
  full_join(pmid_filt_nopmcid)

write.csv(tmp,file="data/all_sources_metadata_2020-03-13_Ana_Cleaned.csv",row.names = FALSE,quote=TRUE)

  
