install.packages("Rcpp")
update.packages("Rcpp")
library(markovchain)

# Code to evaluate a very dumb transition matrix

# I will collapse all 3 columns into one column
raw_data <- na.omit(d5)

# Don't worry about different matches.
# Assume that can make a jump from the end of the match to the start
columns <- as.numeric(as.vector(raw_data$outcome_away))
columns <- rbind(columns,as.numeric(as.vector(raw_data$outcome_home)))
columns <- as.vector(rbind(columns,as.numeric(as.vector(raw_data$outcome_draw))))

# Create a markov chain
mcFit <- markovchainFit(data=columns)

library(Matrix)

# Create a sparse transition matrix
sparse_trans <- as(mcFit$estimate, "sparseMatrix")

# Export sparse matrix
writeMM(sparse_trans,file="dumb_sparse.mm")

states <- names(mcFit$estimate)