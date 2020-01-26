load dumb_sparse.mm
tab = readtable('names.csv');

close all

H = spconvert(dumb_sparse);
spy(H);

% Implement this
%time = 5;
%odds = 2;

% 0   <= odds < 0.2	    1
% 0.2 <= odds < 0.4	    2
% 0.4 <= odds < 0.8	    3
% 0.8 <= odds < 1.2	    4
% 1.2 <= odds < 1.5	    5
% 1.5 <= odds < 2	    6
% 2   <= odds < 3	    7
% 3   <= odds < 5	    8
% 5   <= odds < 10	    9
% 10  <= odds < 30	    10
% 30  <= odds < 200	    11
% 200 <= odds <= 1000	12

val = '30_5';

% Create initial vector
s = size(H);
pi = zeros(1,s(1));

% Look up position
pi = ismember(tab.x,{val})';

%pi(pos) = 1;

plot(pi);
hold on;
H_=H^50;  % Evaluate probability 20 steps ahead
pi_new = pi*H_;
plot(pi_new);

hold off;

% Find values in descending order
desc_vals = sort(pi_new,'descend');
index = find(pi_new == desc_vals(1));
index(2) = find(pi_new == desc_vals(2));
index(3) = find(pi_new == desc_vals(3));
vals = desc_vals(1:3);

% Look up vals
tab(index,2)
vals
