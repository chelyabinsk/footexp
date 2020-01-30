# Script to test the BP model 
setwd("H:\\betting\\footexp\\BP Model 1")
# Open the model file
model<-read.csv("bp_model.csv")
model$t <- 1:length(model[,1])
  

#1006110231
#1006110280
#1006107245

#[1006042012, 1006110426, 1006110280, 1006107511, 1006105888, 1006105981]

dat <- read.csv("odds.csv")

dd <- sqldf("select distinct event_time, outcome_home, outcome_draw, outcome_away from dat
            where event_id = 1006042012")
dd$outcome_draw <- mapvalues(dd$outcome_draw, from = c("Evens"), to = c(1))
dd$outcome_home <- mapvalues(dd$outcome_home, from = c("Evens"), to = c(1))
dd$outcome_away <- mapvalues(dd$outcome_away, from = c("Evens"), to = c(1))

dd$outcome_draw <- sapply(dd$outcome_draw,function(x) as.numeric(eval(parse(text=as.vector(x) ))))
dd$outcome_home <- sapply(dd$outcome_home,function(x) as.numeric(eval(parse(text=as.vector(x) ))))
dd$outcome_away <- sapply(dd$outcome_away,function(x) as.numeric(eval(parse(text=as.vector(x) ))))

ggplot() +
  geom_line(data=model,aes(t,conf_u)) +
  geom_line(data=model,aes(t,conf_l)) +
  geom_line(data=model,aes(t,l_75)) +
  geom_line(data=model,aes(t,l_25)) +
  
  geom_point(data=dd,aes(event_time,outcome_draw),col=4) +
  geom_point(data=dd,aes(event_time,outcome_home),col=6) +
  geom_point(data=dd,aes(event_time,outcome_away),col=11) +
  
  geom_hline(yintercept = 1, linetype=2,col="red") + 
  geom_vline(xintercept = 45,linetype=3,col="blue") + 
  geom_hline(yintercept = 2.5,linetype=5,col="yellow") +
  coord_cartesian(xlim = c(0,90),ylim=c(0,2.5))

