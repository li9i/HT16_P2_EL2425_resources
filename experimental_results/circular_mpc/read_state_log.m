clear all
close all
st = 150;
en = 380;
M = csvread('circular_mpc_states_log.csv');
plot(M(st:en,1), M(st:en,2))
hold on
plot(M(st:en,5), M(st:en,6))
axis([-1 3 -2.6 1.5])
% axis([-1 3 -2 1.5])
axis equal

figure
plot(M(:,8)*180/pi)

r = 1.5;
x_c = 0.95;
y_c = -0.1;
circ = zeros(360,2);
for i = 1:360
  circ(i,1) = x_c + r * cos(pi / 180 * i);
  circ(i,2) = y_c + r * sin(pi / 180 * i);
end

min_dists = zeros(1, en-st);
for i = st:en
  % The distances of all the points in the trajectory to the vehicle
  dists = sqrt((circ(:,1)-M(i,1)).^2 + (circ(:,2)-M(i,2)).^2);

  % The index of the point that is the closest to the vehicle
  [~, idx] = min(dists);
  
  min_dists(i) = dists(idx);
end

figure
plot(min_dists(st:en))
grid
