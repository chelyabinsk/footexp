# Code to follow up from chain_gen.r file

d_win <- sqldf("select * from d9 where win_chain = 1")
d_lose <- sqldf("select * from d9 where win_chain = 0")

# Select data that started high
d_win_sample <- sqldf("
                      select t1.* from d_win as t1
                      
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
                      
                      -- where count < 10
                      
                      order by t1.event_id, chain_n, event_time
                      ")

ggplot(data=d_win,aes(x=event_time,y=odds,group=event_time)) +
  #geom_point() #+
  geom_boxplot(data=d_win,aes(x=event_time,y=odds,group=event_time)) +
  #geom_line() #+
  #xlim(0, 100) + 
  #ylim(0,700) +
  #geom_vline(xintercept=45,colour="red", linetype = "longdash") +
  
  coord_cartesian(ylim=c(0,2.5),xlim=c(30,90)) +
  theme(legend.position = "none")+
  #geom_line(data=d_win_sample,aes(event_time,y=odds,group=factor(event_id),col=factor(event_id))) +
  
  #geom_smooth(data=d_win_sample,aes(event_time,odds)) +
  #geom_point(data=d_win_sample,aes(event_time,odds)) +

  geom_hline(yintercept=1,colour="red", linetype = "longdash") +
  geom_vline(xintercept=45,colour="blue") 

d_test <- sqldf("select * from d9 where count = 100")

ggplot() +
  #geom_boxplot(data=d_win,aes(x=event_time,y=odds,group=event_time)) +
  #geom_point(data=d_win,aes(event_time,odds)) +
  #geom_line(data=d_test,aes(event_time,odds,group=event_id,col=factor(event_id)))+
  geom_point(data=d_test,aes(event_time,odds,group=chain_n,col=factor(chain_n)))+
  geom_smooth(data=d_win_sample,aes(event_time,odds)) +
  coord_cartesian(ylim=c(0,2.5),xlim=c(0,100)) +
  theme(legend.position = "none") +
  geom_hline(yintercept=1,colour="red", linetype = "longdash") +
  geom_vline(xintercept=45,colour="blue") 
  



ggplot(data=d_lose,aes(x=event_time,y=odds,group=event_time)) +
  #geom_point() #+
  geom_boxplot() +
  #geom_line() #+
  #xlim(0, 100) + 
  #ylim(0,30) + 
  #geom_vline(xintercept=45,colour="red", linetype = "longdash") +
  geom_hline(yintercept=1,colour="red", linetype = "longdash") +
  coord_cartesian(ylim=c(0,2.5),xlim=c(45,90))


# Evaluate basic regression
ggplot(data=d_win,aes(x=event_time,y=odds)) +
  geom_point() +
  #geom_boxplot() +
  geom_smooth(method = "glm", se = FALSE,
              method.args = list(family = "poisson"), linetype = "dashed") +
  coord_cartesian(ylim=c(0,2.5))
  #geom_boxplot() +
