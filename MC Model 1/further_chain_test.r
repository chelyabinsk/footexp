# Code to follow up from chain_gen.r file

d_win <- sqldf("select * from d9 where win_chain = 1")
d_lose <- sqldf("select * from d9 where win_chain = 0")

ggplot(data=d_win,aes(x=event_time,y=odds,group=event_time)) +
  #geom_point() #+
  geom_boxplot() +
  #geom_line() #+
  #xlim(0, 100) + 
  #ylim(0,700) +
  #geom_vline(xintercept=45,colour="red", linetype = "longdash") +
  geom_hline(yintercept=1,colour="red", linetype = "longdash") +
  coord_cartesian(ylim=c(0,2.5))


ggplot(data=d_lose,aes(x=event_time,y=odds,group=event_time)) +
  #geom_point() #+
  geom_boxplot() +
  #geom_line() #+
  #xlim(0, 100) + 
  #ylim(0,30) + 
  #geom_vline(xintercept=45,colour="red", linetype = "longdash") +
  geom_hline(yintercept=1,colour="red", linetype = "longdash") +
  coord_cartesian(ylim=c(0,2.5))

