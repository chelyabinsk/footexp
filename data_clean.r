require(sqldf)
require(plyr)
require(ggplot2)
require(data.table)
#remove.packages("Rcpp")
#install.packages("Rcpp")
#update.packages("Rcpp")

# set working directory
setwd("H:\\betting\\footexp\\MC Model 1")
# Read data
d <- read.csv("../odds.csv",header=T,)
#d <- read.csv("../odds_test.csv",header=T,)

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

# Select rows of the matches_g_90 from the big dataframe
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
d4 <- sqldf("select event_id,event_time,outcome_home as odds, 1 as chain_n from d3")
d4 <- rbind(d4,sqldf("select event_id,event_time,outcome_away as odds, 2 as chain_n from d3"))
d4 <- rbind(d4,sqldf("select event_id,event_time,outcome_draw as odds, 3 as chain_n from d3"))

# Remove all of the time zero
d5 <- sqldf("select * from d4 where event_time > 0")
# Remove data no more bets were allowed
d5 <- na.omit(d5)
d5[d5$odds == "",] <- NA
d5 <- na.omit(d5)

# Make event_time into a numeric
d5$event_time <- as.numeric(d5$event_time)

# Remove duplicate times and enter 0 time with 0 odds
empty_events <- sqldf("select distinct event_id, 0 as event_time, 0 as odds, 1 as chain_n from d5")
d6 <- rbind(d5,empty_events)
empty_events <- sqldf("select distinct event_id, 0 as event_time, 0 as odds, 2 as chain_n from d5")
d6 <- rbind(d6,empty_events)
empty_events <- sqldf("select distinct event_id, 0 as event_time, 0 as odds, 3 as chain_n from d5")
d6 <- rbind(d6,empty_events)

#1005635292

d7 <- sqldf("select * from d6 group by event_id, event_time, chain_n order by event_id, chain_n, event_time")

# Find number of entries for each match
ids_count <- sqldf("select event_id, count(event_time) - 1 as num_count from d7 where chain_n = 1 group by event_id")

# Find max time for each event
ids_max_time <- sqldf("select event_id, max(event_time) as max_time from d7 group by event_id")

# Only select matches without missing times
matches_ids <- sqldf("select t1.event_id from ids_count as t1
 inner join (select event_id, max_time from ids_max_time) as t2 on t1.event_id = t2.event_id
 where t1.num_count = t2.max_time ")

d8_1 <- sqldf("select t1.* from d7 as t1 inner join (select event_id from matches_ids) as t2
              on t1.event_id = t2.event_id")

# Find number of entries for each match
ids_count <- sqldf("select event_id, count(event_time) - 1 as num_count from d7 where chain_n = 2 group by event_id")

# Find max time for each event
ids_max_time <- sqldf("select event_id, max(event_time) as max_time from d7 group by event_id")

# Only select matches without missing times
matches_ids <- sqldf("select t1.event_id from ids_count as t1
 inner join (select event_id, max_time from ids_max_time) as t2 on t1.event_id = t2.event_id
 where t1.num_count = t2.max_time ")

d8_2 <- sqldf("select t1.* from d7 as t1 inner join (select event_id from matches_ids) as t2
              on t1.event_id = t2.event_id")

# Find number of entries for each match
ids_count <- sqldf("select event_id, count(event_time) - 1 as num_count from d7 where chain_n = 3 group by event_id")

# Find max time for each event
ids_max_time <- sqldf("select event_id, max(event_time) as max_time from d7 group by event_id")

# Only select matches without missing times
matches_ids <- sqldf("select t1.event_id from ids_count as t1
 inner join (select event_id, max_time from ids_max_time) as t2 on t1.event_id = t2.event_id
 where t1.num_count = t2.max_time ")

d8_3 <- sqldf("select t1.* from d7 as t1 inner join (select event_id from matches_ids) as t2
              on t1.event_id = t2.event_id")

d8 <- rbind(d8_1,d8_2,d8_3)
rm(d8_1,d8_2,d8_3)

#empty_events <- sqldf("select distinct event_id, 0 as event_time, 0 as odds, 2 as chain_n from d5")
#d6 <- rbind(d6,empty_events)
#empty_events <- sqldf("select distinct event_id, 0 as event_time, 0 as odds, 3 as chain_n from d5")
#d6 <- rbind(d6,empty_events)


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

# Add event number column
ids <- sqldf("select distinct event_id from d9")
ids$count <- seq(1:length(ids$event_id))
d9 <- sqldf("select t1.*,t2.count from d9 as t1 
             inner join(
             select event_id, count from ids
             ) as t2
             on t1.event_id = t2.event_id
             order by 
             event_id,
             chain_n,
             event_time
             ")

# Create winning chain flag
d9_ <- d9
d9_$tmp_name <- paste(d9$event_id,"_",d9$chain_n,sep = "")
d9_$event_time <- as.numeric(d9_$event_time)
win_row <- sqldf("
                select distinct t1.event_id, chain_n as win_chain from 
                (
                select t1.event_id, 
                t1.event_time,
                t1.chain_n,
                min(t2.odds) as odds,
                1 as win_chain 
                
                from d9 as t1 
                inner join
                (
                 select event_id, 
                 odds, 
                 max(event_time) as event_time, 
                 chain_n 
                 
                 from d9_ 
                 
                 group by
                 tmp_name
                ) as t2
                on t1.event_id = t2.event_id and 
                   t1.chain_n = t2.chain_n and
                   t1.event_time = t2.event_time
                group by 
                t1.event_id
                ) as t1
                 ")

clean_data <- sqldf("select distinct t1.*,
             case when t1.event_id = t2.event_id and t1.chain_n = t2.win_chain then 1
             else 0
             end as win_chain
             from d9 as t1
             inner join (
             select * from win_row
             ) as t2
             on t1.event_id = t2.event_id
             order by event_id, chain_n, event_time")
rm(d9_,d9,d2,d3,d4,d5,d6,d7,d8,empty_events,ids,ids_count,ids_max_time,matches_g_90,matches_ids,win_row,capt_per_game)

