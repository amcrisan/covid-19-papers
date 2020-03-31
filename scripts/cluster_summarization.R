#following example from https://cran.r-project.org/web/packages/textmineR/vignettes/e_doc_summarization.html 
# with some modifications.
library(dplyr)
library(tidytext)
library(stringr)
library(stringr)
library(stringr)
library(SnowballC)

#To speed things up, I favoured longer sentences with more words. This introduces
#some biases into what it means to be a representative sentence.

load("intermediate_analysis.Rda")

stop_words<-tidytext::stop_words
customStopTerms <-data.frame(word=c("abstract", "text", "abstracttext","introduction","background","method",
                                    "methods","methodology","conclusion","conclusions","objectives","results",
                                    "result","we","materials","purpose","significance","significant","mg","http","com",
                                    "author","copyright","funder","holder−preprin",
                                    "biorxiv", "copyright", "doi", "doi.org", "holder",
                                    "http","peer","preprint","review",
                                    "journal", "articl", "publi","includ", "studi"))
clustName = "immun-vaccin"

clusterSummary<-c()

for(clustName in unique(df$tsneClusterNames)){
  if(clustName == "Not-Clustered") next;
  #Generate Sentences
  #Count of sentences occuring across abstracts
  tidyclust_df <- df %>%
    filter(tsneClusterNames == clustName) %>%
    select(PMID,Title,Abstract) %>%
    mutate(text = paste0(Title,Abstract)) %>%
    unnest_tokens(sentence, text,token = "sentences") %>%
    filter(nchar(sentence)>=250) %>%
    mutate(sentenceTmp = sentence) %>%
    mutate(sentenceID =  sapply(sentence,function(x){digest(x, "md5", serialize = FALSE)}))%>%
    unnest_tokens(word,sentenceTmp) %>%
    anti_join(stop_words) %>%
    anti_join(customStopTerms) %>%
    filter(str_length(word)>2) %>% #only keeps words with length of 2 or greater (AMR, a useful abbreviation, is three characters long)
    filter(!str_detect(word,"\\d")) %>% #get rid of any numbers
    mutate(wordStemmed = wordStem(word))
  
  lowSentence<- tidyclust_df%>%
    group_by(sentenceID) %>%
    count(name='secImp')%>% 
    filter(secImp>20) %>% #wanted sentences that have lots of words
    ungroup()
  
  tidyCorpus_df<-tidyclust_df %>%
    anti_join(lowSentence)%>%
    dplyr::count(sentenceID, wordStemmed,sort = TRUE)
  

  #find the longest sentence
  dtm<-cast_dtm(tidyCorpus_df,sentenceID,wordStemmed,n)
  
  #calculate the cosine similarity
  # get the pairwise distances between each embedded sentence
  cosine_sim<-lsa::cosine(as.matrix(t(dtm)))
  
  #cosine_sim<-lsa::cosine(as.matrix(dtm))
  
  g<-graph_from_adjacency_matrix(cosine_sim,weighted=TRUE,mode = "undirected")
  
  #calcualte eigen vector centrality
  # calculate eigenvector centrality
  ev <- evcent(g)
  
  ev2<-data.frame(sentenceID = names(ev$vector),
                 ev = unname(ev$vector))
  
  # format the result
  sentence<-inner_join(tidyclust_df,ev2) %>%
    group_by(sentenceID) %>%
    sample_n(1) %>%
    ungroup() %>%
    arrange(desc(ev)) %>%
    top_n(5) %>%
    mutate(sentence = gsub("\\[[0-9,\\s+]+\\]","",sentence))

  #Collapse the top five sentences into 
  sentence$clustSummary <- rep(paste(sentence$sentence,collapse="...."),nrow(sentence))
  sentence$tsneClusterNames<-rep(clustName,nrow(sentence))
  
  clusterSummary<-rbind(clusterSummary,
                        sentence[,c("PMID","tsneClusterNames","sentence","clustSummary")])
  
}



