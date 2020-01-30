# use 75% to fit the model
# and 25% to test the model
fit_model <- sqldf("select * from d9 where count < 300")
test_model <- sqldf("select * from d9 where count >= 300")


mcFit <- markovchainFit(data=d9$state)
# Create a sparse transition matrix
sparse_trans <- as(mcFit$estimate, "sparseMatrix")

# Export sparse matrix
writeMM(sparse_trans,file="dumb_sparse.mm")
# Export keys
write.csv(names(mcFit$estimate),"names.csv")

states <- names(mcFit$estimate)
n_games <- length(unique(d9$event_id))
#plot(1:length(d9$state),d9$odds)

# 0-0
# https://www.888sport.com/football/#/filter/football/1005607186
which(names(mcFit$estimate)=="12_8") # 36 82_12 (0.26), 82_9 (0.132)
which(names(mcFit$estimate)=="12_7") # 35 82_12 (0.21), 82_8 (0.167)
which(names(mcFit$estimate)=="12_3") # 31 82_1 (0.2189), 82_12 (0.22)
names(mcFit$estimate)[912]

