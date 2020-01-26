require(Rcpp)
require(markovchain)
require(sqldf)
require(Matrix)


raw_data <- d10


# Create time based state label
raw_data$label <- paste(raw_data$event_time,"_",raw_data$odds,sep = "")
rawdata100 = raw_data$label[1:1000]

# Create a markov chain
mcFit <- markovchainFit(data=rawdata100)

# Create a sparse transition matrix
sparse_trans <- as(mcFit$estimate, "sparseMatrix")

# Export sparse matrix
writeMM(sparse_trans,file="dumb_sparse.mm")
states <- names(mcFit$estimate)