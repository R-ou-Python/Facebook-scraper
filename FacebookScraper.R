library(curl)
library(jsonlite)

# authenticate
accessToken <- "YOUR_TOKEN"
pageId <- "153080620724"
numberOfPagesToScrape <- 5

query = paste("https://graph.facebook.com/v2.8/",pageId,"/feed?fields=id%2Cmessage%2Cplace%2Ccreated_time%2Cmessage_tags%2Cshares%2Clink&limit=100&access_token=",accessToken,sep="")

#extract posts
posts <- data.frame()
for (i in 1:numberOfPagesToScrape) {
  fbPage <- curl_fetch_memory(query)
  postsJson <- fromJSON(rawToChar(fbPage$content),simplifyDataFrame=TRUE)
  postsDf <-  flatten(postsJson$data, recursive = TRUE)
  posts <<- rbind.data.frame(posts,postsDf)
  query = postsJson$paging$'next'
}

#extract likes, shares, comments
postIds <- posts$id
likes <- vector()
shares <- vector()
comments <- vector()
for (post in postIds) {
  reactionURL <- paste("https://graph.facebook.com/v2.8/",post,"?fields=shares%2Clikes.limit(0).summary(true)%2Ccomments.limit(0).summary(true)&access_token=",accessToken,sep="")
  reactions <- curl_fetch_memory(reactionURL)
  reactionsJson <- fromJSON(rawToChar(reactions$content),simplifyDataFrame=TRUE)
  likeCount <- reactionsJson$likes$summary$total_count
  shareCount <- reactionsJson$shares$count
  commentCount <- reactionsJson$comments$summary$total_count
  likes <- c(likes,likeCount)
  shares <- c(shares,shareCount)
  comments <- c(comments,commentCount)
}

#add likes, shares, comments to DF
posts$likes <- likes
posts$shares <- shares
posts$comments <- comments

#remove temp stuff
rm(list= ls()[!(ls() %in% c('posts','accessToken','pageId','numberOfPagesToScrape'))])