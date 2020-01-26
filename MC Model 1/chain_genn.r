require(sqldf)
require(plyr)
require(ggplot2)
require(data.table)

# set working directory
setwd("H:\\betting\\github\\footexp\\MC Model 1")
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
