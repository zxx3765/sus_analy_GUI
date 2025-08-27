%% 该脚本用于构建半车状态空间方程
% 状态变量定义为：
 % X = [xuf - q1;   % 前轮轮胎与路面之间的位移差（前轮动位移）
 %      xur - q2;   % 后轮轮胎与路面之间的位移差（后轮动位移）
 %      xsf - xuf;  % 前悬架动行程（车身与前轮之间的相对位移）
 %      xsr - xur;  % 后悬架动行程（车身与后轮之间的相对位移）
 %      vuf;        % 前轮非簧载质量（轮毂）的垂直速度
 %      vur;        % 后轮非簧载质量的垂直速度
 %      vs;         % 车身质心处的垂直速度（簧载质量）
 %      vtheta];    % 车身俯仰角速度
 %  输出向量 y 定义为：
 % y = [asf;        % 前簧载质量加速度（车身前部加速度）
 %      asr;        % 后簧载质量加速度（车身后部加速度）
 %      vsf - vuf;  % 前悬架相对速度（车身与前轮之间的相对速度）
 %      vsr - vur;  % 后悬架相对速度（车身与后轮之间的相对速度）
 %      auf;        % 前轮非簧载质量加速度
 %      aur;        % 后轮非簧载质量加速度
 %      as;         % 车身质心垂直加速度
 %      atheta];    % 车身俯仰角加速度
 % 控制输入 U = [F1; F2] 表示前后悬架作动器施加的力（主动力）。
ms = 690;      % 簧载质量 (kg)
muf = 40;       % 前非簧载质量 (kg)
mur = 45;       % 后非簧载质量 (kg)
Iyy = 1222;     % 俯仰转动惯量 (kg·m²)
ktf = 200000;   % 前轮胎刚度 (N/m)
ktr = 200000;   % 后轮胎刚度 (N/m)
ksf = 17000;    % 前悬架刚度 (N/m)
ksr = 22000;    % 后悬架刚度 (N/m)
csf = 1500;     % 前悬架阻尼 (N·s/m)
csr = 1500;     % 后悬架阻尼 (N·s/m)
a = 1.3;        % 前轴到质心距离 (m)
b = 1.5;        % 后轴到质心距离 (m)


    % 状态空间矩阵维度
    n = 8;  % 状态维度 [xuf-q1, xur-q2, xsf-xuf, xsr-xur, vuf, vur, vs, vtheta]
    p = 2;  % 输入维度 [F1, F2]
    q = 8;  % 输出维度 [asf, asr, vsf-vuf, vsr-vur, auf, aur, as, atheta]
    
    % 系统矩阵 A (8x8)
    A = zeros(n);
    A(1,5) = 1;
    A(2,6) = 1;
    A(3,5) = -1;
    A(3,7) = 1;
    A(3,8) = -a;
    A(4,6) = -1;
    A(4,7) = 1;
    A(4,8) = b;
    A(5,1) = -ktf/muf;
    A(5,3) = ksf/muf;
    A(5,5) = -csf/muf;
    A(5,7) = csf/muf;
    A(5,8) = -a*csf/muf;
    A(6,2) = -ktr/mur;
    A(6,4) = ksr/mur;
    A(6,6) = -csr/mur;
    A(6,7) = csr/mur;
    A(6,8) = b*csr/mur;
    A(7,3) = -ksf/ms;
    A(7,4) = -ksr/ms;
    A(7,5) = csf/ms;
    A(7,6) = csr/ms;
    A(7,7) = -(csf+csr)/ms;
    A(7,8) = (a*csf-b*csr)/ms;
    A(8,3) = a*ksf/Iyy;
    A(8,4) = -b*ksr/Iyy;
    A(8,5) = -a*csf/Iyy;
    A(8,6) = b*csr/Iyy;
    A(8,7) = (a*csf - b*csr)/Iyy;
    A(8,8) = -(a^2*csf + b^2*csr)/Iyy;
    
    % 输入矩阵 B (8x2)
    B = zeros(n,p);
    B(5,1) = -1/muf;
    B(6,2) = -1/mur;
    B(7,1) = 1/ms;
    B(7,2) = 1/ms;
    B(8,1) = -a/Iyy;
    B(8,2) = b/Iyy;

    % 噪声输入矩阵 E (8x2)
    E = zeros(n,p);
    E(1,1) = -1;
    E(2,2) = -1;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
    
    % 输出矩阵 C (8x8)
    C = zeros(q,n);
    % asf (前簧载质量加速度)
    C(1,3) = -ksf/ms-ksf*a^2/Iyy;
    C(1,4) = ksr*a*b/Iyy-ksr/ms;
    C(1,5) = csf/ms+csf*a^2/Iyy;
    C(1,6) = csr/ms-csr*a*b/Iyy;
    C(1,7) = -csf/ms-csf*a^2/Iyy-csr/ms+csr*a*b/Iyy;
    C(1,8) = -csr*b/ms+csr*a*b^2/Iyy+csf*a^3/Iyy+csf*a/ms;
    % asr (后簧载质量加速度)
    C(2,3) = -ksf/ms+ksf*a*b/Iyy;
    C(2,4) = -ksr*b^2/Iyy-ksr/ms;
    C(2,5) = csf/ms-csf*a*b/Iyy;
    C(2,6) = csr/ms+csr*b^2/Iyy;
    C(2,7) = -csf/ms-csr*b^2/Iyy-csr/ms+csf*a*b/Iyy;
    C(2,8) = -csr*b/ms-csf*a^2*b/Iyy-csr*b^3/Iyy+csf*a/ms;
    % vsf-vuf (前悬架相对速度)
    C(3,5) = -1;
    C(3,7) = 1;
    C(3,8) = -a;
    % vsr-vur (后悬架相对速度)
    C(4,6) = -1;
    C(4,7) = 1;
    C(4,8) = b;
    % auf (前非簧载质量加速度)
    C(5,1) = -ktf/muf;
    C(5,3) = ksf/muf;
    C(5,5) = -csf/muf;
    C(5,7) = csf/muf;
    C(5,8) = -a*csf/muf;
    % aur (后非簧载质量加速度)
    C(6,2) = -ktr/mur;
    C(6,4) = ksr/mur;
    C(6,6) = -csr/mur;
    C(6,7) = csr/mur;
    C(6,8) = b*csr/mur;
    % as (簧载质量质心加速度)
    C(7,3) = -ksf/ms;
    C(7,4) = -ksr/ms;
    C(7,5) = csf/ms;
    C(7,6) = csr/ms;
    C(7,7) = -(csf+csr)/ms;
    C(7,8) = (a*csf-b*csr)/ms;
    % atheta (俯仰角加速度)
    C(8,3) = a*ksf/Iyy;
    C(8,4) = -b*ksr/Iyy;
    C(8,5) = -a*csf/Iyy;
    C(8,6) = b*csr/Iyy;
    C(8,7) = (a*csf - b*csr)/Iyy;
    C(8,8) = -(a^2*csf + b^2*csr)/Iyy;
    
    % 直接传递矩阵 D (8x2)
    D = zeros(q,p);
    D(1,1) = 1/ms+a^2/Iyy;    % asf
    D(1,2) = 1/ms-a*b/Iyy;
    D(2,1) = 1/ms-a*b/Iyy;
    D(2,2) = 1/ms+b^2/Iyy;    % asr
    D(5,1) = -1/muf;    % auf
    D(6,2) = -1/mur;    % aur
    D(7,1) = 1/ms;    % as
    D(7,2) = 1/ms;
    D(8,1) = -a/Iyy;    % atheta
    D(8,2) = b/Iyy;

% if rank(ctrb(A,B)) == size(A,1)
%     disp('系统能控');
% else
%     disp('系统不完全能控');
% end

%% 步骤 2: 验证可观测性
Ob = obsv(A, C);   % 计算可观测性矩阵
rank_Ob = rank(Ob);
% fprintf('可观测性矩阵秩 = %d (状态维度 n = %d)\n', rank_Ob, n);

% if rank_Ob < n
%     error('系统不可观测! 无法设计观测器');
% else
%     disp('系统完全可观测，可以设计观测器');
% end
%% 步骤 3: 设计 Luenberger 观测器 (极点配置法)
% 选择期望的观测器极点 (比系统极点快2-5倍)
sys_poles = eig(A); % 系统开环极点
% fprintf('系统开环极点: %.2f ± %.2fj\n', real(sys_poles(1)), imag(sys_poles(1)));

% 设置观测器极点 (左半平面，实部更负)
obs_poles = 3 * real(sys_poles) - 5; % 加速收敛

% 使用极点配置计算增益矩阵 L
L = place(A', C', obs_poles)'; % 注意转置
%% 验证广义坐标SS
M_o = [ms, 0, 0, 0; 
    0, Iyy, 0, 0; 
    0, 0, muf, 0; 
    0, 0, 0, mur];
C_o = [csf + csr, b*csr - a*csf, -csf, -csr;
    b*csr - a*csf, csf*a^2 + csr*b^2, a*csf, -b*csr;
    -csf, a*csf, csf, 0;
    -csr, -b*csr, 0, csr];
K_o = [ksf + ksr, b*ksr - a*ksf, -ksf, -ksr;
    b*ksr - a*ksf, ksf*a^2 + ksr*b^2, a*ksf, -b*ksr;
    -ksf, a*ksf, ksf + ktf, 0;
    -ksr, -b*ksr, 0, ksr + ktr];
Bu_o = [1, 1; -a, b; -1, 0; 0, -1];
Bw_o = [0, 0; 0, 0; ktf, 0; 0, ktr];
A_gc  = [zeros(4), eye(4); -M_o\K_o, -M_o\C_o];           % 8x8
Bu_gc = [zeros(4,2); M_o\Bu_o];          % 8x2   (原 u 的输入矩阵)
Bw_gc = [zeros(4,2); M_o\Bw_o];         % 8x2   (路面)
% 可以测的量包括 俯仰角 垂向加速度 前后簧下加速度 前后相对位移
Cy_s_gc = [0 1 0 0 0 0 0 0; A_gc(5,:); A_gc(7,:); A_gc(8,:); 1,  a, -1,  0,  0, 0, 0, 0;1, -b,  0, -1,  0, 0, 0, 0];
Dyu_s_gc = [0 0; Bu_gc(5,:); Bu_gc(7,:); Bu_gc(8,:); 0 0; 0 0;];
Dyw_s_gc = [0 0; Bw_gc(5,:); Bw_gc(7,:); Bw_gc(8,:); 0 0; 0 0;];


