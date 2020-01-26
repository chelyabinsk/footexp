# 888 Sports experiment

### MC Model 1

#### Workflow

##### chain_gen.r 
Opens odds.csv file and only keep matches that have been going from time 0 to at least 90 without any missing minutes.

There are 3 columns (outcome_home, outcome_draw, outcome_away) they specify the odds for home win, draw, or a away win.

Then the 3 columns are combined into one column.

event_time and odds group columns are combined to create a state. E.g. *10_2* means group 2 at minute 10

Markov chain is calculated from the transition between states

Since there are too many states  common states are put into groups to reduce computational time

| Odds Range | Group |
|:-----------|------:|
| 0 <= odds < 0.2 | 1 |
| 0.2 <= odds < 0.4 | 2 |
| 0.4 <= odds < 0.8 | 3 |
| 0.8 <= odds < 1.2 | 4 |
| 1.2 <= odds < 1.5 | 5 |
| 1.5 <= odds < 2 | 6 |
| 2 <= odds < 3| 7 |
| 3 <= odds < 5| 8 |
| 5 <= odds < 10| 9 |
| 10 <= odds < 30| 10 |
| 30 <= odds < 200| 11 |
| 200 <= odds <= 1000| 12 |

Markov Chain is calculated from the chain of events using the function *markovchainFit*. Alternatively, can try using Python package PyEMMA to calculate the
transition matrix from the sample [http://www.emma-project.org/v2.2.7/api/generated/msmtools.estimation.transition_matrix.html].

Following the Markov Chain calculation transition matrix is converted into the sparse matrix and then exported as a *dumb_sparse.mm*

__NOTE: writeMM puts the dimensions of the matrix on the second line. This line confuses MATLAB so make sure to remove it!__

TODO: Evaluate performance of the model

