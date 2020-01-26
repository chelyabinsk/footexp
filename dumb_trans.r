#install.packages("Rcpp")
#update.packages("Rcpp")
require(Rcpp)
require(markovchain)
require(Matrix)

# Create a sparse transition matrix
sparse_trans <- as(mcFit$estimate, "sparseMatrix")

# Export sparse matrix
writeMM(sparse_trans,file="dumb_sparse.mm")
states <- names(mcFit$estimate)