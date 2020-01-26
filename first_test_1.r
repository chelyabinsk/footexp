require(sqldf)
require(plyr)
#require(dplyr)
require(ggplot2)
require(data.table)

setwd("H:/MY STUFF/Betting_Seva")

d <- read.csv("odds.csv",header=T,)

# Find number captured games
n_games <- sqldf::sqldf("select count(distinct event_id) from d")[1,1]

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

# Find outcome for each match
capt_per_game$outcome_type <- ifelse(capt_per_game$max_home > capt_per_game$max_away,1,
                                     ifelse(capt_per_game$max_home == capt_per_game$max_away,2,
                                            ifelse(capt_per_game$max_home < capt_per_game$max_away,3,0)
                                            )
                                    )
#  1 - home win, 2 - draw, 3 - away win

                                     


# find matches whose last recorded minute is > 90
matches_g_80 <- sqldf("
                      select distinct event_id from capt_per_game where max_minute >= 90
                      ")

# Select rows of the matches_g_80 from the big dataframe
d2 <- sqldf("
select t1.*
from d as t1 inner join 
 (
 select event_id from matches_g_80
 ) as t2
on t1.event_id == t2.event_id
order by event_id,event_time
            ")

d3 <- sqldf("
select
t2.outcome_type as outcome_type,
t1.*
from d2 as t1 left join 
            (
            select event_id, outcome_type from capt_per_game
            ) as t2
            on t1.event_id == t2.event_id
")

# Select useful columns
d4 <- sqldf("
select distinct
event_id,
event_time,
outcome_type,
outcome_home,
outcome_draw,
outcome_away,
event_home_score,
event_away_score,
outcome_startingOdds,
outcome_unexpectedOddsTrend
from d3 order by event_id,event_time asc
")

d5 <- d4

# Replace blanks with 0
d5$outcome_home <- mapvalues(d4$outcome_home, from = c("","Evens"), to = c(0,1))
d5$outcome_draw <- mapvalues(d4$outcome_draw, from = c("","Evens"), to = c(0,1))
d5$outcome_away <- mapvalues(d4$outcome_away, from = c("","Evens"), to = c(0,1))

# Evaluate text as numeric
d5$outcome_home <- mapvalues(d5$outcome_home, from = levels(d5$outcome_home), 
                             to = (sapply(levels(d5$outcome_home), function(x) as.numeric(eval(parse(text=x)))))
                             )
d5$outcome_draw <- mapvalues(d5$outcome_draw, from = levels(d5$outcome_draw), 
                             to = (sapply(levels(d5$outcome_draw), function(x) as.numeric(eval(parse(text=x)))))
)
d5$outcome_away <- mapvalues(d5$outcome_away, from = levels(d5$outcome_away), 
                             to = (sapply(levels(d5$outcome_away), function(x) as.numeric(eval(parse(text=x)))))
)


# Create winning odds column
# d6 is the winning odds database
d6 <- sqldf("
select
event_id,
event_time,
case when outcome_type = 1 then outcome_home
when outcome_type = 2 then outcome_draw
when outcome_type = 3 then outcome_away
end as winning_odds
from d5
            ")

d6$winning_odds <- as.numeric(d6$winning_odds)

unique_matches <- sqldf("select count(distinct event_id) from d6")[1,1]

ggplot(data=d6, aes(x=event_time, y=winning_odds, group=event_id)) +
  geom_line(aes(color=event_id))+
  #geom_point(aes(color=event_id)) +
  scale_x_continuous(breaks = seq(0, 90, 10)) +
  scale_y_continuous(breaks = seq(0, 10, 1)) +  
  ylim(0, 10) +
  xlim(45,100) +
  geom_hline(yintercept=1,linetype="dashed",color="red")

# Create lost odds column
d7 <- sqldf("
select
event_id,
event_time,
case when outcome_type = 1 then outcome_away
when outcome_type = 2 then outcome_away
when outcome_type = 3 then outcome_home
end as lost_odds
from d5
            ")
 
d8 <- sqldf("
select
event_id*10 as event_id,
event_time,
case when outcome_type = 1 then outcome_draw
when outcome_type = 2 then outcome_home
when outcome_type = 3 then outcome_draw
end as lost_odds
from d5
            ")

# Bind two lost datasets
# d9 is the losing odds database
d9 <- rbind(d7,d8)
d9$lost_odds <- as.numeric(d9$lost_odds)


ggplot(data=d9, aes(x=event_time, y=lost_odds, group=event_id)) +
  geom_line(aes(color=event_id))+
  #geom_point(aes(color=event_id)) +
  scale_x_continuous(breaks = seq(0, 90, 10)) +
  scale_y_continuous(breaks = seq(0, 10, 1)) +  
  ylim(0, 5) +
  xlim(45,100) +
  geom_hline(yintercept=1,linetype="dashed",color="red")


# Remove the odds when the bookmakers stop making them 

d9[d9$lost_odds == 0,] <- NA
d6[d6$winning_odds == 0,] <- NA


# Remove pre-match odds from d9 & d6

d9 <- na.omit(d9)  # Losing odds
d6 <- na.omit(d6)  # Winning odds


# Remove all of the time zero
d9New <- sqldf("select * from d9 where event_time > 0")
d6New <- sqldf("select * from d6 where event_time > 0")

# Remove duplicate times and enter 0 time with 0 odds
event_ids1 <- sqldf("select distinct event_id, 0 as event_time, 0 as lost_odds from d9New")
event_ids2 <- sqldf("select distinct event_id, 0 as event_time, 0 as winning_odds from d6New")
d9New <- rbind(d9New,event_ids1)
d6New <- rbind(d6New,event_ids2)
d9New <- sqldf("select * from d9New group by event_id, event_time order by event_id, event_time")
d6New <- sqldf("select * from d6New group by event_id, event_time order by event_id, event_time")

# Find number of entries for each match
ids_count1 <- sqldf("select event_id, count(event_time) - 1 as num_count from d9New group by event_id")
ids_count2 <- sqldf("select event_id, count(event_time) - 1 as num_count from d6New group by event_id")

# Find max time for each event
ids_max_time1 <- sqldf("select event_id, max(event_time) as max_time from d9New group by event_id")
ids_max_time2 <- sqldf("select event_id, max(event_time) as max_time from d6New group by event_id")

# Only select matches without missing times
matches_ids1 <- sqldf("select t1.event_id from ids_count as t1
inner join (select event_id, max_time from ids_max_time) as t2 on t1.event_id = t2.event_id
where t1.num_count = t2.max_time ")

matches_ids2 <- sqldf("select t1.event_id from ids_count as t1
inner join (select event_id, max_time from ids_max_time) as t2 on t1.event_id = t2.event_id
where t1.num_count = t2.max_time ")

d9New <- sqldf("select t1.* from d9New as t1 inner join (select event_id from matches_ids1) as t2 
             on t1.event_id = t2.event_id")
d6New <- sqldf("select t1.* from d6New as t1 inner join (select event_id from matches_ids2) as t2 
             on t1.event_id = t2.event_id")

# Combined winning-losing dataset

names(d9New) <- c("event_id","event_time","odds") # Losing 
names(d6New) <- c("event_id","event_time","odds") # Winning 
d10 <- rbind(d9New,d6New)





