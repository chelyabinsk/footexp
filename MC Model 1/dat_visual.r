## Data visualisation

# Use d7
d7$odds <- mapvalues(d7$odds, from = c("Evens"), to = c(1))
d7$odds_f <- sapply(d7$odds,function(x) as.numeric(eval(parse(text=as.vector(x) ))))

dd <- sqldf("select * from d7 where event_id = 1006047847")
ggplot(data=dd,aes(x=event_time,odds_f)) +
 geom_point()
  
