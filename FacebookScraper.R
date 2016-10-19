library(curl)
library(jsonlite)

# authenticate
access_token <- "YOUR_TOKEN"

queryPosts = paste("https://graph.facebook.com/v2.8/153080620724/feed?fields=id%2Cmessage%2Ccreated_time%2Cmessage_tags%2Cshares%2Clink&limit=100&access_token=",access_token,sep="")

#extract posts
allposts <- data.frame()
for (i in 1:5) {
  fbPage <- curl_fetch_memory(queryPosts)
  postsJson <- fromJSON(rawToChar(fbPage$content),simplifyDataFrame=TRUE)
  postsDf <-  flatten(postsJson$data, recursive = TRUE)
  allposts <<- rbind.data.frame(allposts,postsDf)
  queryPosts = postsJson$paging$'next'
}

#extract likes, shares, comments
posts <- allposts$id
likes <- vector()
shares <- vector()
comments <- vector()
for (post in posts) {
  reactionURL <- paste("https://graph.facebook.com/v2.8/",post,"?fields=shares%2Clikes.limit(0).summary(true)%2Ccomments.limit(0).summary(true)&access_token=",access_token,sep="")
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
allposts$likes <- likes
allposts$shares <- shares
allposts$comments <- comments

