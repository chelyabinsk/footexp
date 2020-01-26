load dumb_sparse.mm

close all

H = spconvert(dumb_sparse);
spy(H);

% Create initial vector
s = size(H);
pi = zeros(1,s(1));

pi(1) = 1;

plot(pi);
hold on;
H_=H^1;  % Evaluate probability 20 steps ahead
pi_new = pi*H_;
plot(pi_new);

hold off;
