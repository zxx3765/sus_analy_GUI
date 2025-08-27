%% 该脚本用于创建解耦半车状态空间矩阵

% 状态空间矩阵维度
n = 8;  % 状态维度 []
p = 3;  % 输入维度 []
q = 3;  % 输出维度 []

% 参数定义
ms = 690;      % 簧载质量 (kg)
muf = 40;      % 前非簧载质量 (kg)
mur = 45;      % 后非簧载质量 (kg)
I = 1222;      % 俯仰转动惯量 (kg·m²)
ktf = 200000;  % 前轮胎刚度 (N/m)
ktr = 200000;  % 后轮胎刚度 (N/m)
ksf = 17000;   % 前悬架刚度 (N/m)
ksr = 22000;   % 后悬架刚度 (N/m)
csf = 1500;    % 前悬架阻尼 (N·s/m)
csr = 1500;    % 后悬架阻尼 (N·s/m)
a = 1.3;       % 前轴到质心距离 (m)
b = 1.5;       % 后轴到质心距离 (m)
l = a + b;


%% 使用验证后的 df1 作为最终模型

%系统矩阵 A (8x8)
lambda_1 = (ms*a^2 - l*ms*a + I) / (ms*a^2 - 2*l*ms*a + ms*l^2 + I);
lambda_2 = (l^2) / (ms*a^2 - 2*l*ms*a + ms*l^2 + I);
mcf = ms*b / l;

A_df = zeros(n);
A_df(1,2) = 1;
A_df(3,4) = 1;
A_df(5,6) = 1;
A_df(7,8) = 1;

A_df(2,1)=ksf*l/(ms*(a-l));
A_df(2,2)=csf*l/(ms*(a-l));
A_df(2,3)=-ksf*l/(ms*(a-l));
A_df(2,4)=-csf*l/(ms*(a-l));
A_df(2,5) = ksf*l / (ms*(a - l));
A_df(2,6) = csf*l / (ms*(a - l));
A_df(2,7) = -ksf*l / (ms*(a - l));
A_df(2,8) = -csf*l / (ms*(a - l));

A_df(4,1) = ksf / muf;
A_df(4,2) = csf / muf;
A_df(4,3) = -(ksf + ktf) / muf;
A_df(4,4) = -csf / muf;

A_df(6,1) = ksf*(1/mcf - lambda_2);
A_df(6,2) = csf*(1/mcf - lambda_2);
A_df(6,3) = -ksf*(1/mcf - lambda_2);
A_df(6,4) = -csf*(1/mcf - lambda_2);
A_df(6,5) = ksf*(1/mcf - lambda_2);
A_df(6,6) = csf*(1/mcf - lambda_2);
A_df(6,7) = -ksf*(1/mcf - lambda_2);
A_df(6,8) = -csf*(1/mcf - lambda_2);

A_df(8,5) = ksf / muf;
A_df(8,6) = csf / muf;
A_df(8,7) = -(ksf + ktf) / muf;
A_df(8,8) = -csf / muf;

B_df = zeros(n, p);
B_df(2,2) = -l / (ms*(a - l));
B_df(4,1) = ktf / muf;
B_df(4,2) = -1 / muf;
B_df(6,2) = -(1/mcf - lambda_2);
B_df(6,3) = lambda_1;

C_df = zeros(q, n);
C_df(1,:) = A_df(2,:) + A_df(6,:);
C_df(2,:) = A_df(4,:) + A_df(8,:);
C_df(3,:) = A_df(2,:);

D_df = zeros(q, p);
D_df(1,:) = B_df(2,:) + B_df(6,:);
D_df(2,:) = B_df(4,:) + B_df(8,:);
D_df(3,:) = B_df(2,:);

