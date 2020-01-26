require(sqldf)
require(plyr)
require(ggplot2)
require(data.table)
#remove.packages("Rcpp")
#install.packages("Rcpp")
#update.packages("Rcpp")
require(markovchain)
require(Matrix)

# set working directory
setwd("H:\\betting\\footexp\\MC Model 1")
# Read data
d <- read.csv("../odds.csv",header=T,)

# Find last minute for each game
# Sometimes goals are disallowed grrrr
capt_per_game <- sqldf("select
      t1.event_id,
      --- count(event_state) as num_captures,
      t1.event_home_score as max_home,
      t1.event_away_score as max_away,
      t1.event_time as max_minute
      from d as t1 
      INNER JOIN
      ( select
        event_id,max(event_time) as max_time
        from d 
        group by event_id
      ) as t2 
       on t1.event_id = t2.event_id
       where t2.max_time = t1.event_time
       --- group by t1.event_id
      
      ")


# find matches whose last recorded minute is > 90
matches_g_90 <- sqldf("
                      select distinct event_id from capt_per_game where max_minute >= 90
                      ")

# Select rows of the matches_g_80 from the big dataframe
d2 <- sqldf("
select distinct t1.*
from d as t1 inner join 
 (
 select event_id from matches_g_90
 ) as t2
on t1.event_id == t2.event_id
order by event_id,event_time
            ")
d3 <- sqldf("
select distinct
t1.event_id,
t1.event_time,
t1.outcome_home,
t1.outcome_draw,
t1.outcome_away
from d2 as t1 inner join 
            (
            select event_id from capt_per_game
            ) as t2
            on t1.event_id == t2.event_id
")

# Combine three columns into one chain
d4 <- sqldf("select event_id,event_time,outcome_home as odds from d3")
d4 <- rbind(d4,sqldf("select event_id,event_time,outcome_away as odds from d3"))
d4 <- rbind(d4,sqldf("select event_id,event_time,outcome_draw as odds from d3"))

# Remove all of the time zero
d5 <- sqldf("select distinct * from d4 where event_time > 0")
# Remove data no more bets were allowed
d5 <- na.omit(d5)
d5[d5$odds == "",] <- NA
d5 <- na.omit(d5)

# Make event_time into a numeric
d5$event_time <- as.numeric(d5$event_time)

# Remove duplicate times and enter 0 time with 0 odds
empty_events <- sqldf("select distinct event_id, 0 as event_time, 0 as odds from d5")
d6 <- rbind(d5,empty_events)
d7 <- sqldf("select * from d6 group by event_id, event_time order by event_id, event_time")

# Find number of entries for each match
ids_count <- sqldf("select event_id, count(event_time) - 1 as num_count from d7 group by event_id")

# Find max time for each event
ids_max_time <- sqldf("select event_id, max(event_time) as max_time from d7 group by event_id")

# Only select matches without missing times
matches_ids <- sqldf("select t1.event_id from ids_count as t1
inner join (select event_id, max_time from ids_max_time) as t2 on t1.event_id = t2.event_id
where t1.num_count = t2.max_time ")

d8 <- sqldf("select t1.* from d7 as t1 inner join (select event_id from matches_ids) as t2 
             on t1.event_id = t2.event_id")


# Replace text odds with numerical values
d8$odds <- mapvalues(d8$odds, from = c("Evens"), to = c(1))

# Evaluate text as numeric
d9 <- d8
d9$odds <- sapply(d8$odds,function(x) as.numeric(eval(parse(text=x))))

#ggplot(data=d9, aes(x=event_time, y=odds, group=event_id)) +
#  geom_line(aes(color=event_id))+
#  #geom_point(aes(color=event_id)) +
#  scale_x_continuous(breaks = seq(0, 90, 10)) +
#  scale_y_continuous(breaks = seq(0, 10, 1)) +  
#  ylim(0, 2) +
#  #xlim(45,100) +
#  geom_hline(yintercept=1,linetype="dashed",color="red")

# Evaluate the markov chain
#plot(table(d9$odds))

# Group odds into 12 "boxes"
d9$odds_group <- 
ifelse(d9$odds < 0.2, 1,
ifelse(d9$odds < 0.4, 2,
ifelse(d9$odds < 0.8, 3,
ifelse(d9$odds < 1.2, 4,
ifelse(d9$odds < 1.5, 5,
ifelse(d9$odds < 2, 6,
ifelse(d9$odds < 3, 7,
ifelse(d9$odds < 5, 8,
ifelse(d9$odds < 10, 9,
ifelse(d9$odds < 30, 10,
ifelse(d9$odds < 200, 11,
12
)))))))))))
#table(d9$odds_group)

d9$state <- paste(d9$event_time,"_",d9$odds_group,sep = "")
mcFit <- markovchainFit(data=d9$state)
# Create a sparse transition matrix
sparse_trans <- as(mcFit$estimate, "sparseMatrix")

# Export sparse matrix
writeMM(sparse_trans,file="dumb_sparse.mm")

states <- names(mcFit$estimate)

#plot(1:length(d9$state),d9$odds)