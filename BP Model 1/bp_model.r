# Boxplot based model

d_win <- sqldf("select * from clean_data where win_chain = 1")
d_lose <- sqldf("select * from clean_data where win_chain = 0")

d_win_sample <- sqldf("select t1.* from d_win as t1

inner join (
                      select t1.event_id from d_win as t1
                      inner join (
                      select event_id from d_win
                      where event_time = 1
                      ) as t2
                      on t1.event_id = t2.event_id
                      where t1.odds > 1 and event_time = 1
                      ) as t2
                      on t1.event_id = t2.event_id

                      inner join (
                      select t1.event_id from d_win as t1
                      inner join (
                      select event_id from d_win
                      where event_time = 1
                      ) as t2
                      on t1.event_id = t2.event_id
                      where t1.odds > 1 and event_time = 45 and t1.odds < 2
                      ) as t3
                      on t1.event_id = t3.event_id

                      inner join (
                      select t1.event_id from d_win as t1
                      inner join (
                      select event_id from d_win
                      where event_time = 1
                      ) as t2
                      on t1.event_id = t2.event_id
                      where t1.odds <1.5 and event_time = 60
                      ) as t4
                      on t1.event_id = t4.event_id

                      inner join (
                      select t1.event_id from d_win as t1
                      inner join (
                      select event_id from d_win
                      where event_time = 1
                      ) as t2
                      on t1.event_id = t2.event_id
                      where t1.odds < 1 and event_time = 80
                      ) as t5
                      on t1.event_id = t5.event_id

                      inner join (
                      select t1.event_id from d_win as t1
                      inner join (
                      select event_id from d_win
                      where event_time = 1
                      ) as t2
                      on t1.event_id = t2.event_id
                      where t1.odds < 1 and event_time = 81
                      ) as t6
                      on t1.event_id = t6.event_id

                      inner join (
                      select t1.event_id from d_win as t1
                      inner join (
                      select event_id from d_win
                      where event_time = 1
                      ) as t2
                      on t1.event_id = t2.event_id
                      where t1.odds < 1 and event_time = 82
                      ) as t7
                      on t1.event_id = t7.event_id

                      inner join (
                      select t1.event_id from d_win as t1
                      inner join (
                      select event_id from d_win
                      where event_time = 1
                      ) as t2
                      on t1.event_id = t2.event_id
                      where t1.odds < 1 and event_time = 83
                      ) as t8
                      on t1.event_id = t8.event_id

                      inner join (
                      select t1.event_id from d_win as t1
                      inner join (
                      select event_id from d_win
                      where event_time = 1
                      ) as t2
                      on t1.event_id = t2.event_id
                      where t1.odds > 0.5 and event_time = 60
                      ) as t9
                      on t1.event_id = t9.event_id



                      ")

# Do the basic analysis to remove outliers
boxplot(odds ~ event_time,data=d_win_sample,cex.axis=0.5,ylim=c(0,3))
mod <- lm(odds ~ event_time,d_win_sample)
cooksd <- cooks.distance(mod)
plot(cooksd, pch="*", cex=2, main="Influential Obs by Cooks distance",ylim=c(0,0.02))
abline(h = 4*mean(cooksd, na.rm=T), col="red")  # add cutoff line
text(x=1:length(cooksd)+1, y=cooksd, labels=ifelse(cooksd>4*mean(cooksd, na.rm=T),names(cooksd),""), col="red")  # add labels

influential <- as.numeric(names(cooksd)[(cooksd > 4*mean(cooksd, na.rm=T))])

#head(d_win_sample[influential, ])

d_win_sample <- d_win_sample[-influential,]

# Visualise the model
b<-boxplot(odds ~ event_time,data=d_win_sample,cex.axis=0.5,ylim=c(0,3))
# Upper confidence
conf_u <- b$conf[1,]
# Lower confidence
conf_l <- b$conf[2,]

# 75% 
l_75 <- b$stats[2,]
# 25%
l_25 <- b$stats[4,]

lines(conf_u,col="red")
lines(conf_l,col="red")

lines(l_75,col="blue")
lines(l_25,col="blue")

# Export the model
write.csv(data.frame(conf_u,conf_l,l_75,l_25),"bp_model.csv",row.names = F)
