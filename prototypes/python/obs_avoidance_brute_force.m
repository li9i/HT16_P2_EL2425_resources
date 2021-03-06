% Created by Pedro Lima (pfrdal@kth.se) and Valerio Turri (turri@kth.se)
% EL2700 MPC Course Prof. Mikael Johansson
%%
yalmip('clear')

clear all;
close all;
clc

%% Parameters definition
% model parameters
params.Ts                   = 0.01;                      % sampling time (both of MPC and simulated vehicle)
params.nstates              = 3;                        % number of states
params.ninputs              = 1;                        % number of inputs
params.l_f                  = 0.17;
params.l_r                  = 0.16;

% control parameters
params.N                    = 100;                        % The horizon
params.Q                    = [100 0 0; 0 100 0; 0 0 0.01];
% params.Q                    = eye(3);
params.R                    = 0.01;

% initial conditions
params.x0                   = 1.75;                        % initial x coordinate
params.y0                   = 0;                        % initial y coordinate
params.v0                   = 20;                       % initial speed
params.psi0                 = pi/2;                        % initial heading angle

params.N_max                = 20;                        % maximum number of simulation steps




%% Simulation environment
% initialization

z       = zeros(params.N_max+1, params.nstates);             % z(k,j) denotes state j at step k-1
mov_ref = zeros(params.N_max+1, params.nstates);             % z(k,j) denotes state j at step k-1
u       = zeros(params.N_max, params.ninputs);             % z(k,j) denotes input j at step k-1
z(1,:)  = [params.x0, params.y0, params.psi0]; % definition of the intial state


k = 0;
circ = trajectory();
figure
plot(circ(:,1), circ(:,2))
hold on
axis equal



  

while (k < params.N_max)
  k = k+1;
  
  dists = sqrt((circ(:,1)-z(k,1)).^2 + (circ(:,2)-z(k,2)).^2);

  [~, idx] = min(dists);
  
  mov_ref(k,:) = circ(mod(idx+15, 360) + 1, :);
    
  % The linearized model's matrices
  params.linear_A = [
    1 0 -params.Ts * params.v0 *sin(z(k,3));
    0 1 params.Ts * params.v0 * cos(z(k,3));
    0 0 1];

  params.linear_B = [
    -params.Ts * params.l_r * params.v0 / 0.33 * sin(z(k,3));
    params.Ts * params.v0 * params.l_r/ 0.33 * cos(z(k,3));
    params.Ts*params.v0/0.33];

  % Ensure stability
%   [params.Qf,~,~] = dare(params.linear_A, params.linear_B, params.Q, params.R);


  yalmip('clear')

  % The predicted state and control variables
  z_mpc = sdpvar(params.N+1, params.nstates);
  u_mpc = sdpvar(params.N, params.ninputs);


  % Initial conditions. Reset constraints and cost
  constraints = [];
  J = 0;

  for i = 1:params.N
    J = J + ...
      (z_mpc(i,:)-mov_ref(k,:)) * params.Q * (z_mpc(i,:)-mov_ref(k,:))' +  ...
      u_mpc(i,:) * params.R * u_mpc(i,:)';

    % Model contraints
    constraints = [constraints, ...
      z_mpc(i+1,:)' == params.linear_A * z_mpc(i,:)' + params.linear_B * u_mpc(i,:)'];


    % Input constraints
    constraints = [constraints, ...
      -pi/3 <= u_mpc(i,1) <= pi/3];
  end


  %  terminal cost
%   J = J + (z_mpc(params.N+1, :) - mov_ref(k,:)) * params.Qf * (z_mpc(params.N+1, :)-mov_ref(k,:))';




  assign(z_mpc(1,:), z(k,:));

  % Options
  ops = sdpsettings('solver', 'quadprog');

  % Optimize
  optimize([constraints, z_mpc(1,:) == z(k,:)], J, ops);

  %% snatch first predicted input 
  u(k,:) = value(u_mpc(1,:));


  % simulate the vehicle
  z(k+1,:) = car_sim(z(k,:), u(k,:), params);

  
  
end

plot(z(:,1), z(:,2))
hold off

figure
hold on
plot(circ(:,1), circ(:,2))
plot(mov_ref(:,1), mov_ref(:,2))
axis equal
hold off

figure
hold on
plot(circ(:,1), circ(:,3))
plot(z(:,1),z(:,3))
axis equal