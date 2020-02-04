# Script to test the BP model 
setwd("/home/pirate/Documents/GITHUB/footexp/BP Model 1")
# Open the model file
model<-read.csv("bp_model.csv")
model$t <- 1:length(model[,1])
  
# [1006110426, 1006105888]
setwd("/home/pirate/Documents/GITHUB/footexp")
dat <- read.csv("odds.csv")

d_ <- d[d$current_time]
  
  sqldf("select distinct event_id,current_time from d ")

dd <- sqldf("select event_id, event_time,
            odds,chain_n,count from clean_data 
            where 
            count < 99 and count > 10
            --- event_id > 1006112509
            --- and 
            --- count <= 507
            --- and 
            --- chain_n=3
            and
            win_chain = 1
            ")

ggplot() +
  geom_line(data=model,aes(t,conf_u)) +
  geom_line(data=model,aes(t,conf_l)) +
  geom_line(data=model,aes(t,l_75)) +
  geom_line(data=model,aes(t,l_25)) +
  
  geom_line(data=model,aes(t,uu)) +
  geom_line(data=model,aes(t,ll)) +
  
  #geom_point
  geom_point(data=dd,aes(event_time,odds,group=event_id,colour=factor(chain_n) )) +
  
  #geom_point(data=dd,aes(event_time,odds,group=event_id,colour=factor(event_id) )) +
  
  geom_hline(yintercept = 1, linetype=2,col="red") + 
  geom_vline(xintercept = 45,linetype=3,col="blue") + 
  geom_hline(yintercept = 2.5,linetype=5,col="yellow") +
  coord_cartesian(xlim = c(0,100),ylim=c(0,2.5)) +
  theme(legend.position = "none")

t <- sqldf("select distinct event_id, from clean_data where count > 499 and win_chain = 1")
ngames <- length(unique(clean_data$event_id))
