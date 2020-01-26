# 888 Sports experiment

### MC Model 1
#### chain_gen.r 
Opens odds.csv file and only keep matches that have been going from time 0 to at least 90 without any missing minutes.

There are 3 columns (outcome_home, outcome_draw, outcome_away) which specify the odds for home win, draw, or a away win.

Then the 3 columns are combined into one column.

event_time and odds columns are combined to create a state

Markov chain is calculated from the transition between states

-- TODO: Group states to reduce the number of total states
