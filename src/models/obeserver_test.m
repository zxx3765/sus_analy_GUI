%% 状态空间观测器设计 MATLAB 示例
% 系统模型: 
%   dx/dt = A*x + B*u + E*w  (过程噪声 w)
%   y = C*x + D*u

%% 步骤 1: 定义系统矩阵 (替换为你的实际矩阵)
% 系统维度
n = size(A, 1);    % 状态维度
m = size(B, 2);    % 输入维度
p = size(C, 1);    % 输出维度
q = size(E, 2);    % 噪声维度

%% 步骤 2: 验证可观测性
Ob = obsv(A, C);   % 计算可观测性矩阵
rank_Ob = rank(Ob);
fprintf('可观测性矩阵秩 = %d (状态维度 n = %d)\n', rank_Ob, n);

if rank_Ob < n
    error('系统不可观测! 无法设计观测器');
else
    disp('系统完全可观测，可以设计观测器');
end

%% 步骤 3: 设计 Luenberger 观测器 (极点配置法)
% 选择期望的观测器极点 (比系统极点快2-5倍)
sys_poles = eig(A); % 系统开环极点
fprintf('系统开环极点: %.2f ± %.2fj\n', real(sys_poles(1)), imag(sys_poles(1)));

% 设置观测器极点 (左半平面，实部更负)
obs_poles = 3 * real(sys_poles) - 5; % 加速收敛

% 使用极点配置计算增益矩阵 L
L = place(A', C', obs_poles)'; % 注意转置
fprintf('\nLuenberger 观测器增益矩阵 L:\n');
disp(L);

% 观测器方程:
%   dx_hat/dt = A*x_hat + B*u + L*(y - y_hat)
%   y_hat = C*x_hat + D*u

%% 步骤 4: 设计卡尔曼滤波器 (需要噪声统计特性)
% 假设噪声特性 (需要根据实际系统设置)
Q_kalman = diag([0.1]);  % 过程噪声协方差 (q x q)
R_kalman = diag([0.01]); % 测量噪声协方差 (p x p)

% 设计连续时间卡尔曼滤波器增益
[Kest, L_kf, P] = kalman(ss(A, [B E], C, [D zeros(p, q)]), Q_kalman, R_kalman);

% 等价方法:
% L_kf = lqe(A, E, C, Q_kalman, R_kalman);

fprintf('\n卡尔曼滤波器增益矩阵 L_kf:\n');
disp(L_kf);

% 卡尔曼滤波器方程:
%   dx_hat/dt = A*x_hat + B*u + L_kf*(y - y_hat)
%   y_hat = C*x_hat + D*u

%% 步骤 5: 仿真比较两种观测器
dt = 0.01;          % 时间步长
t_sim = 0:dt:10;    % 仿真时间
N = length(t_sim);

% 初始化变量
x = zeros(n, N);      % 真实状态
x_hat_luen = zeros(n, N); % Luenberger 估计状态
x_hat_kf = zeros(n, N);   % Kalman 估计状态
y = zeros(p, N);        % 系统输出
u = zeros(m, N);        % 控制输入

% 输入信号 (示例：阶跃+正弦)
u(1, t_sim >= 1) = 0;
u(1, :) = 0+ 0.5*sin(2*t_sim);
u(2, t_sim >= 1) = 0;
u(2, :) = 0- 0.5*sin(2*t_sim);
% 初始状态
x0 = [0; 0;0; 0;0; 0;0; 0;];     % 真实初始状态
x_hat0 = [0; 0;0; 0;0; 0;0; 0;];      % 观测器初始估计

x(:,1) = x0;
x_hat_luen(:,1) = x_hat0;
x_hat_kf(:,1) = x_hat0;

% 过程噪声 (有界随机噪声)
w = [0.001*randn(q, N)]; % 过程噪声

% 测量噪声 (添加到输出)
v = 0.05*randn(p, N); % 测量噪声

% 主仿真循环
for k = 1:N-1
    % 系统动态 (连续时间积分)
    dx = A*x(:,k) + B*u(:,k) + E*w(:,k);
    x(:,k+1) = x(:,k) + dx*dt;
    
    % 系统输出 (添加测量噪声)
    y(:,k) = C*x(:,k) + D*u(:,k) + v(:,k);
    
    % Luenberger 观测器更新
    y_hat_luen = C*x_hat_luen(:,k) + D*u(:,k);
    dx_hat_luen = A*x_hat_luen(:,k) + B*u(:,k) + L*(y(:,k) - y_hat_luen);
    x_hat_luen(:,k+1) = x_hat_luen(:,k) + dx_hat_luen*dt;
    
    % 卡尔曼滤波器更新
    y_hat_kf = C*x_hat_kf(:,k) + D*u(:,k);
    dx_hat_kf = A*x_hat_kf(:,k) + B*u(:,k) + L_kf*(y(:,k) - y_hat_kf);
    x_hat_kf(:,k+1) = x_hat_kf(:,k) + dx_hat_kf*dt;
end

% 最后一步输出
y(:,N) = C*x(:,N) + D*u(:,N) + v(:,N);

%% 步骤 6: 绘制结果
figure('Position', [100 100 1200 800]);

% 绘制状态 1
subplot(3,1,1);
plot(t_sim, x(1,:), 'k', 'LineWidth', 2); hold on;
plot(t_sim, x_hat_luen(1,:), 'b--', 'LineWidth', 1.5);
plot(t_sim, x_hat_kf(1,:), 'r:', 'LineWidth', 1.5);
title('状态 1 估计');
ylabel('x_1');
legend('真实状态', 'Luenberger 估计', 'Kalman 估计');
grid on;

% 绘制状态 2
subplot(3,1,2);
plot(t_sim, x(2,:), 'k', 'LineWidth', 2); hold on;
plot(t_sim, x_hat_luen(2,:), 'b--', 'LineWidth', 1.5);
plot(t_sim, x_hat_kf(2,:), 'r:', 'LineWidth', 1.5);
title('状态 2 估计');
ylabel('x_2');
grid on;

% 绘制误差
subplot(3,1,3);
error_luen = vecnorm(x - x_hat_luen);
error_kf = vecnorm(x - x_hat_kf);
semilogy(t_sim, error_luen, 'b-', 'LineWidth', 1.5); hold on;
semilogy(t_sim, error_kf, 'r-', 'LineWidth', 1.5);
title('估计误差 (范数)');
ylabel('||x - x_{hat}||');
xlabel('时间 (s)');
legend('Luenberger 误差', 'Kalman 误差');
grid on;

%% 步骤 7: 分析稳态误差
steady_idx = t_sim > 5; % 稳态区间

mean_error_luen = mean(error_luen(steady_idx));
mean_error_kf = mean(error_kf(steady_idx));

fprintf('\n稳态误差分析 (t>5s):\n');
fprintf('Luenberger 观测器平均误差: %.4f\n', mean_error_luen);
fprintf('卡尔曼滤波器平均误差: %.4f\n', mean_error_kf);