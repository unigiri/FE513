# Load libraries
library(RMySQL)
library(quantmod)
library(tm)
library(hunspell)
library(wordcloud)
library(e1071)

#````````````````````````````````````````````````````````
# Problem 1
#````````````````````````````````````````````````````````
# load driver for SQL
drv <- dbDriver("MySQL")

con <- dbConnect(drv, user = "gang", password = "gang", 
                 host = "localhost", dbname = "fe513_twitter")

#checking table

dbListTables(con)

# Step 1 - creating a data frame for unique user_ids
SQLtext1 <- "SELECT DISTINCT(user_id) FROM twitter_message"

unique_userid <- dbSendQuery(con, SQLtext1)

unique_users <- dbFetch(unique_userid)
unique_users

# Step 2 - creating a data frame for random user_ids
random_users <- data.frame(unique_users[sample(nrow(unique_users), 3, replace = FALSE, prob = NULL),])

random_users
names(random_users)[1] <- paste("user_id")
random_users

random_users[1,1]
random_users[2,1]
random_users[3,1]

dbWriteTable(con, "random_users", random_users, overwrite = TRUE)

dbReadTable(con, "random_users")

# step 3 - create query to extract all of those user tweets
SQLtext2 <- "SELECT * FROM twitter_message where user_id IN (SELECT user_id FROM random_users)"

r_user_query <- dbSendQuery(con, SQLtext2)

r_user_tweets <- dbFetch(r_user_query)

# step 4 - combine tweets from the same user into one variable. As a result, you will have 3 variables(long strings) in R.
user1 <- r_user_tweets[which(r_user_tweets$user_id == random_users[1,1]), ]
user2 <- r_user_tweets[which(r_user_tweets$user_id == random_users[2,1]), ]
user3 <- r_user_tweets[which(r_user_tweets$user_id == random_users[3,1]), ]


combined_user1_tweets <- paste(user1$tweets, collapse = " ")
combined_user2_tweets <- paste(user2$tweets, collapse = " ")
combined_user3_tweets <- paste(user3$tweets, collapse = " ")

# step 5 - Creating list of all non-english words from each set and removing non-ASCII characters
combined_user1_tweets <- iconv(combined_user1_tweets, "latin1", "ASCII", sub="")
combined_user2_tweets <- iconv(combined_user2_tweets, "latin1", "ASCII", sub="")
combined_user3_tweets <- iconv(combined_user3_tweets, "latin1", "ASCII", sub="")

u1_nonen <- unlist(hunspell_find(combined_user1_tweets))
u2_nonen <- unlist(hunspell_find(combined_user2_tweets))
u3_nonen <- unlist(hunspell_find(combined_user3_tweets))

nonenglishset <- c(u1_nonen, u2_nonen, u3_nonen)

# step 5.1 - remove all punctuations
ut <- Corpus(VectorSource(c(combined_user1_tweets, combined_user2_tweets, combined_user3_tweets)))
utnopunc <- tm_map(ut, removePunctuation)
uttolower <- tm_map(utnopunc, content_transformer(tolower))

# step 5.2 - remove all numbers
utnonum <- tm_map(uttolower, removeNumbers)

# step 5.3 - remove stop words
utnostop <- tm_map(utnonum, removeWords, stopwords("en"))

# step 5.4 - remove non-english words
utnoeng <- tm_map(utnostop, removeWords, nonenglishset)

# step 6 - Create the term-document matrxi and plot the wordclouds
TM1 <- TermDocumentMatrix(utnoeng)
M1 <- as.matrix(TM1)

final <- data.frame(word = rownames(M1),freq1=M1[,1], freq2 = M1[,2], freq3 = M1[,3])
par(mfrow = c(1, 3))
wordcloud(words = final$word, freq = final$freq1, min.freq = 2, colors=brewer.pal(8, "Dark2"))
wordcloud(words = final$word, freq = final$freq2, min.freq = 4.5, colors=brewer.pal(8, "Dark2"))
wordcloud(words = final$word, freq = final$freq3, min.freq = 5, colors=brewer.pal(8, "Dark2"))


#````````````````````````````````````````````````````````
# Problem 2
#````````````````````````````````````````````````````````

# Problem 1
# load driver for SQL
drv <- dbDriver("MySQL")

con <- dbConnect(drv, user = "gang", password = "gang", 
                 host = "localhost", dbname = "fe513_twitter")

#checking table

dbListTables(con)

# Step 1 - creating a data frame for unique user_ids
unique_userid <- dbSendQuery(con, "SELECT DISTINCT(user_id) FROM twitter_message")

unique_users <- dbFetch(unique_userid)
unique_users

# Step 2 - creating a data frame for random user_ids
random_users <- data.frame(unique_users[sample(nrow(unique_users), 3, replace = FALSE, prob = NULL),])

random_users
names(random_users)[1] <- paste("user_id")
random_users

random_users[1,1]
random_users[2,1]
random_users[3,1]

dbWriteTable(con, "random_users", random_users, overwrite = TRUE)

dbReadTable(con, "random_users")

# step 3 - create query to extract all of those user tweets
r_user_query <- dbSendQuery(con, "SELECT * FROM twitter_message where user_id IN (SELECT user_id FROM random_users)")

r_user_tweets <- dbFetch(r_user_query)

ps2_nonen <- unlist(hunspell_find(r_user_tweets$tweets))

# step 4 - make a label(index) vector for those tweets/documents. 
# The label is the user id you have. Thus, all documents posted 
# by one user should have the same label, and you will have 3 unique 
# labels in total.

cleaned_user1_tweets <- iconv(r_user_tweets$tweets, "latin1", "ASCII", sub="")

PS2_cleaned_table <- cbind(r_user_tweets$user_id, cleaned_user1_tweets)

PS2 <- as.data.frame(PS2_cleaned_table)

print.sum <- summary(PS2)

# step 5.1 - remove all punctuations
utps2 <- Corpus(VectorSource(c(cleaned_user1_tweets)))
utnopuncps2 <- tm_map(utps2, removePunctuation)
uttolowerps2 <- tm_map(utnopuncps2, content_transformer(tolower))

# step 5.2 - remove all numbers
utnonumps2 <- tm_map(uttolowerps2, removeNumbers)

# step 5.3 - remove stop words
utnostopps2 <- tm_map(uttolowerps2, removeWords, stopwords("en"))

# step 5.4 - remove non-english words
utnoengps2 <- tm_map(utnostopps2, removeWords, ps2_nonen)

# step 6 - Create the term-document matrix
TMPS2 <- DocumentTermMatrix(utnoengps2)
M2 <- as.matrix(TMPS2)
ncol(M2)

# DFM2 <- as.data.frame((M2))
# DFM2[,1][DFM2[,1] == "1"] <- random_users[1,1]
# DFM2[,2][DFM2[,2] == "1"] <- random_users[2,1]
# DFM2[,3][DFM2[,3] == "1"] <- random_users[3,1]

# Step 7 - run kmeans clustering
kmRes <- kmeans(M2, 3, nstart = 20)

# Step 8 - use table() function in R showing the difference between cluster results and user id label.
ktable <- table(res =  kmRes$cluster, real = PS2$V1)

#returns cluster label
cmRes <- cmeans(M2, centers = 3, iter.max = 100)
head(cmRes$cluster)

#return membership (the probability of one data point belongs to one group. )
#the clutser label is based on max(membership)
head(cmRes$membership)

# Step 7 - run hierarchical cluster
d <- dist(M2, method = "euclidean")
HclustResult <- hclust(d, method="ward.D")

plot(HclustResult) 

groups <- cutree(HclustResult, k=3) # cut tree into n clusters
# draw dendogram with red borders around the n clusters
rect.hclust(HclustResult, k=3, border="red")

# Step 8 - use table() function in R showing the difference between cluster results and user id label.
htable <- table(res = groups, real = PS2$V1)

dbDisconnect(con)
