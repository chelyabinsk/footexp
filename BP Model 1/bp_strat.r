# Script to identify set of effective rules

# Pick some game
# Find number of draws in data
n_draws <- sqldf("select count(distinct event_id) from clean_data where win_chain=3 ")[1,1]
n_games <- length(unique(clean_data$event_id))



#for(n in 1:93){
n_corr = 0
n_wrong = 0
margin = 0
for(n in 1:n_games){

dd <- sqldf(paste("select event_id, event_time,
            odds,chain_n,count,win_chain from clean_data 
            where
            count =",n,
            " and
            event_time > 20
            --- event_id > 1006112509
            --- and 
            --- count <= 507
            --- and 
            --- chain_n=3
            --- and
            --- win_chain = 1
            "))

dd_1 <- sqldf(paste("select event_id, event_time,
            odds,chain_n,count,win_chain from clean_data 
            where
            count =",n,
                  " and
            event_time > 20
            --- event_id > 1006112509
            --- and 
            --- count <= 507
            and 
            chain_n=1
            --- and
            --- win_chain = 1
            "))
dd_2 <- sqldf(paste("select event_id, event_time,
            odds,chain_n,count,win_chain from clean_data 
            where
            count =",n,
                    " and
            event_time > 20
            --- event_id > 1006112509
            --- and 
            --- count <= 507
            and 
            chain_n=2
            --- and
            --- win_chain = 1
            "))

dd_3 <- sqldf(paste("select event_id, event_time,
            odds,chain_n,count,win_chain from clean_data 
            where
            count =",n,
                    " and
            event_time > 20
            --- event_id > 1006112509
            --- and 
            --- count <= 507
            and 
            chain_n=3
            --- and
            --- win_chain = 1
            "))

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
  #coord_cartesian(xlim = c(54,56),ylim=c(0,2.5)) +
  coord_cartesian(xlim = c(0,90),ylim=c(0,5)) +
  theme(legend.position = "none")

# Check that "draw" is always within the expected region 
# after the 20th minute
is_valid = T
for(i in 1:length(dd_3[,1]) ){
  # Check current odds
  if( dd_3[i,3] <= model$l_25[dd_3[i,2]]*1
     &&
     dd_3[i,3] >= model$l_75[dd_3[i,2]]*0.9
     && is_valid == T
  ){
  }
  else{
    is_valid = F
    #print(c(i,dd_3[i,2]))
  }
  if(i < length(dd_3[,1])){
   if(dd_3[i+1,3] - dd_3[i,3] > 0.2 ){
      is_valid = F
    }
  }
  
  if(!is.na(dd_1[i,3]) && !is.na(dd_2[i,3])){
    if(abs(dd_1[i,3] - dd_2[i,3]) < 1){
      is_valid=F
    }
  }
  
   if(i < length(dd_1[,1])){
     if((dd_1[i+1,3] - dd_1[i,3]) > 0.4 ){
       is_valid = F
     }
   }
  if(i < length(dd_1[,1])){
    if((dd_1[i,3] - dd_1[i+1,3]) > 0.2 ){
      is_valid = F
    }
  }
  if(i < length(dd_2[,1])){
    if((dd_2[i+1,3] - dd_2[i,3]) > 0.4 ){
      is_valid = F
    }
  }
  if(i < length(dd_2[,1])){
    if((dd_2[i,3] - dd_2[i+1,3]) > 0.2 ){
      is_valid = F
    }
  }
  
  if(dd_3[i,3] <= 2 && dd_3[i,2] > 45){
    # Consider putting a bet
    break
  }
}

if(is_valid){
  if(max(dd_3$win_chain)==3){
    n_corr = n_corr +1;
    margin = margin + dd_3[i,3]
  }else{
    n_wrong = n_wrong + 1;
  }
  #print(c(is_valid,max(dd_3$win_chain),n,dd_3[i,2],dd_3[i,3]))
  print(c(n_corr,n_wrong,margin-n_wrong,n))
}
}

