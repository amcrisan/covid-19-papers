#Ordering documents by relevance.
library(lsa)
library(dplyr)
library(tidytext)
library(igraph)

load("intermediate_analysis.Rda")

#Use the cosine similarity to created a weight graph
#Use pagerank to rank articles.

pageRank_df<-c()

for(clustName in unique(df$tsneClusterNames)){
  if(clustName == "Not-Clustered") next;
  
  #filter by cluster
  clust_sha <-filter(df, tsneClusterNames == clustName) %>% select(PMID)
  
  tidyclust_df<-filter(tidy_df,PMID %in% clust_sha$PMID)
  
  #cosine similarity for documents in a cluster
  dtm<-cast_dtm(tidyclust_df,PMID,wordStemmed,tf_idf)
  
  #calculate the cosine similarity
  cosine_sim<-lsa::cosine(as.matrix(t(dtm)))
  cosine_sim[cosine_sim<0.5]<-0
  g2<-graph_from_adjacency_matrix(cosine_sim,weighted=TRUE,mode = "undirected")
  
  #page rank
  pr<-page_rank(g2,directed = FALSE)$vector
  
  pageRank_df<-rbind(pageRank_df,
                     cbind(names(pr),pr))
  
}

pageRank_df<-data.frame(PMID = pageRank_df[,1],
                        clustRank = as.numeric(pageRank_df[,2]),
                        stringsAsFactors = FALSE)

df2<-dplyr::left_join(df,pageRank_df,by="PMID")

