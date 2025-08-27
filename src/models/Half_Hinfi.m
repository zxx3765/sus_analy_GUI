%% === 0) 你的线性模型（来自线化或符号） ===
% x: 8x1, v:2x1, w:2x1, y_m: p x 1 (传感器)
% 你已有 A, Bu, Bw, Cm (测量矩阵)
% 去耦后 Bv = Bu * Einv
%
% 权重类型切换说明：
% 在 "%% 2) 定义动态/静态权重" 部分，可以通过修改 weight_type 参数来切换权重类型：
% weight_type = 'dynamic';  % 使用动态权重（默认）
% weight_type = 'static';   % 使用静态权重
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
l = a + b;
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
A  = [zeros(4), eye(4); -M_o\K_o, -M_o\C_o];           % 8x8
Bu = [zeros(4,2); M_o\Bu_o];          % 8x2   (原 u 的输入矩阵)
Bw = [zeros(4,2); M_o\Bw_o];         % 8x2   (路面)
% Cy_o: 解耦输出矩阵
Cy_d = [1 0 0 0; 
      0 1 0 0];  % 例如：z_s, phi
E = -Cy_d
Einv = [(b*ms)/l, -Iyy/l; (a*ms)/l, Iyy/l];
alpha = -Cy_d*inv(M_o)*[K_o C_o] ;
% u = Einv * (v - alpha) 解耦控制输入
Bv = Bu * Einv;
A_v = A - Bv*alpha; % 解耦控制后的A矩阵
Dyu_d = zeros(size(C_o,1), 2);
Dyw_d = zeros(size(C_o,1), 2);

%Cy_s 传感器输出矩阵
% 可以测的量包括 俯仰角 俯仰角速度 垂向速度 垂向加速度 前后簧下加速度 前后相对位移
%Cy_s_index 6*16
Cy_s_index = [0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
              0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0;
              0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0;
              0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0;
              0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0;
              0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1;
              1 -a -1 0 0 0 0 0 0 0 0 0 0 0 0 0;
              1 b 0 -1 0 0 0 0 0 0 0 0 0 0 0 0];
Cy_s = Cy_s_index*[eye(8);A];
Cyv_s = Cy_s - Cy_s_index*[eye(8);Bv*alpha];
Dyu_s = Cy_s_index*[zeros(8,2);Bu];
Dyv_s = Cy_s_index*[zeros(8,2);Bv];
Dyw_s = Cy_s_index*[zeros(8,2);Bw];
%% === 1) 构造性能输出 z ===
% 1.1 车身加速度 (ddot y) = Cddot*x + Ddv*v + Ddw*w
% 用二阶关系： [ddz_s; ddphi] = Cyy*A*x + Cyy*Bv*v + Cyy*Bw*w  （近似）
Cy_Jacc_index = [0 0 0 0 1 0 0 0;   % 提取 a_s
                0 0 0 0 0 1 0 0;
                0 0 0 0 0 0 1 0;
                0 0 0 0 0 0 0 1;];  % 提取 a_phi
Cy_Jacc = Cy_Jacc_index * A_v;
Dyv_Jacc   = Cy_Jacc_index * Bv;
Dyw_Jacc   = Cy_Jacc_index * Bw;

% 1.2 悬架挠度 z_sf - z_uf, z_sr - z_ur
Cy_Jsus = [ 1,  a, -1,  0,  0, 0, 0, 0;   % (z_s + l/2*phi - z_ul)
          1, -b,  0, -1,  0, 0, 0, 0];

% 1.3 轮胎挠度 z_ul - q_l, z_ur - q_r
Cy_Jtire = [0 0 1 0 0 0 0 0;
          0 0 0 1 0 0 0 0];
Dw_tire = -eye(2);   % 减去 [q_l; q_r]

%% 2) 定义动态/静态权重
% 添加权重类型选择参数（'dynamic' 或 'static'）
weight_type = 'static';  % 选择权重类型

if strcmp(weight_type, 'static')
    %% === 静态权重设计 ===
    % 静态权重矩阵定义
    % 车身加速度权重 - 关注乘坐舒适性
    W_acc = 1;      % 车身垂向加速度权重
    W_pitch = 1;    % 车身俯仰加速度权重
    
    % 悬架挠度权重 - 防止悬架行程过大
    W_sus_f = 5;    % 前悬架挠度权重
    W_sus_r = 5;    % 后悬架挠度权重
    
    % 轮胎挠度权重 - 保证轮胎接地性
    W_tire_f = 2;    % 前轮胎挠度权重
    W_tire_r = 2;    % 后轮胎挠度权重
    
    % 控制输入权重 - 限制控制力
    W_u1 = 0.1;      % 前控制力权重
    W_u2 = 0.1;      % 后控制力权重
    
    % 构造加权的性能输出矩阵
    % Cz_weighted = [W_acc * Cy_Jacc(1,:);           % 加权车身垂向加速度
    %                W_pitch * Cy_Jacc(2,:);         % 加权车身俯仰加速度
    %                W_sus_f * Cy_Jsus(1,:);         % 加权前悬架挠度
    %                W_sus_r * Cy_Jsus(2,:);         % 加权后悬架挠度
    %                W_tire_f * Cy_Jtire(1,:);       % 加权前轮胎挠度
    %                W_tire_r * Cy_Jtire(2,:);       % 加权后轮胎挠度
    %                zeros(2,8)];                     % 控制输入项（在D矩阵中处理）
    % 
    % Dzv_weighted = [W_acc * Dyv_Jacc(1,:);         % 车身加速度对控制输入的传递
    %                 W_pitch * Dyv_Jacc(2,:);       
    %                 zeros(4,2);                     % 悬架和轮胎挠度对控制输入
    %                 W_u1, 0;                        % 控制输入1权重
    %                 0, W_u2];                       % 控制输入2权重
    % 
    % Dzw_weighted = [W_acc * Dyw_Jacc(1,:);         % 车身加速度对扰动的传递
    %                 W_pitch * Dyw_Jacc(2,:);       
    %                 zeros(2,2);                     % 悬架挠度对扰动
    %                 W_tire_f * Dw_tire(1,:);       % 轮胎挠度对扰动
    %                 W_tire_r * Dw_tire(2,:);       
    %                 zeros(2,2)];                    % 控制输入对扰动

    % 构造加权的性能输出矩阵 去掉加速度项
    Cz_weighted = [W_sus_f * Cy_Jsus(1,:);         % 加权前悬架挠度
                   W_sus_r * Cy_Jsus(2,:);         % 加权后悬架挠度
                   zeros(2,8)];                     % 控制输入项（在D矩阵中处理）
    Dzv_weighted = [zeros(2,2);                     % 悬架和轮胎挠度对控制输入
                    W_u1, 0;                        % 控制输入1权重
                    0, W_u2];                       % 控制输入2权重

    Dzw_weighted = [zeros(2,2);                     % 悬架挠度对扰动     
                    zeros(2,2)];                    % 控制输入对扰动
    
else
    %% === 动态权重设计 ===
    % 车身加速度权重，低频区域增强加速度性能
    W_Jacc   = tf([ (2*pi*8)^2  2*0.7*(2*pi*8)  0 ], [ 1  2*0.05*(2*pi*0.5)  (2*pi*0.5)^2 ]);
    W_Jacc   = blkdiag(W_Jacc, W_Jacc);   % heave & roll 同样权重
    
    % 悬架挠度权重（防打击/限位）——中低频抑制
    W_Jsus = 50*tf(1,[1/ (2*pi*10) 1]);   % 低通放大相对位移
    W_Jsus = blkdiag(W_Jsus, W_Jsus);
    
    % 轮胎挠度权重（抓地）——中高频抑制
    W_Jtire = 2*tf([1/ (2*pi*15) 1],1);   % 高通样式
    W_Jtire = blkdiag(W_Jtire, W_Jtire);
    
    % 控制"力度"权重（不要过度激烈）
    W_Jv = ss(0.1*eye(2));
    
    % 命名权重块的 I/O
    W_Jacc.u = {'y_J1','y_J2'};   W_Jacc.y = {'Jacc1','Jacc2'};
    W_Jsus.u = {'y_J3','y_J4'}; W_Jsus.y = {'Jsus1','Jsus2'};
    W_Jtire.u= {'y_J5','y_J6'};     W_Jtire.y= {'Jt1','Jt2'};
    W_Jv.u   = {'v1','v2'};     W_Jv.y   = {'Ju1','Ju2'};
end

%% === 3) 构造广义植物 P ===
if strcmp(weight_type, 'static')
    %% 静态权重情况：直接构造P
    % 组装性能输出矩阵
    Cy_J_all = [Cz_weighted];  % 8x8 的加权性能输出矩阵
    
    Dyv_J_all = [Dzv_weighted];  % 8x2 的加权控制输入直通项
    
    Dyw_J_all = [Dzw_weighted];  % 8x2 的加权扰动直通项
    
    % 构造广义植物 P: 输入 [w; v], 输出 [z; y]
    P = ss(A_v, [Bw Bv], ...
           [Cy_J_all; Cyv_s], ...
           [Dyw_J_all Dyv_J_all; Dyw_s Dyv_s]);
    
else
    %% 动态权重情况：使用connect函数
    % 2.4 组装性能输出 z = [Wacc*ddot y; Wsus*z_sus; Wtire*z_tire; Wu*v]
    Cy_J  = [Cy_Jacc;
           Cy_Jsus;
           Cy_Jtire;];
    
    Dyw_J = [Dyw_Jacc;
           zeros(2,2);
           Dw_tire;];
    Dyv_J = [Dyv_Jacc;
           zeros(2,2);
           zeros(2,2);];
    
    % 1) 裸植物：输入 [w; v]，输出 [y; dd; sus; tire]
    G = ss(A_v, [Bw Bv], [ Cyv_s;Cy_J;], [Dyw_s Dyv_s ;Dyw_J  Dyv_J]);
    
    % 给输入/输出命名（用于 connect 自动布线）
    G.InputName  = {'w1','w2','v1','v2'};
    G.OutputName = {'y1','y2','y3','y4','y5','y6','y_J1','y_J2','y_J3','y_J4','y_J5','y_J6'};
    
    % 连接得到广义植物 P:  inputs=[w1 w2 v1 v2], outputs=[z; y]
    P = connect(G, W_Jacc, W_Jsus, W_Jtire, W_Jv, ...
        {'w1','w2','v1','v2'}, ...
        {'Jacc1','Jacc2','Jsus1','Jsus2','Jt1','Jt2','Ju1','Ju2','y1','y2','y3','y4','y5','y6'});
end

%% 强制显式化 + 规约（很关键）
fprintf('Converting to explicit state-space...\n');
P = ss(P);
fprintf('Original P: %d states\n', size(P.A,1));

% 强制最小实现以获得显式状态空间
P = minreal(P, 1e-8);
fprintf('After minreal P: %d states\n', size(P.A,1));

% 确保数值稳定性
if ~isempty(P.A) && all(isfinite(P.A(:))) && all(isfinite(P.B(:))) && ...
   all(isfinite(P.C(:))) && all(isfinite(P.D(:)))
    fprintf('State-space realization is valid and finite.\n');
else
    error('State-space realization contains infinite or NaN values');
end

nmeas = 6;   % y 的维度（传感器输出）
ncon  = 2;   % v 的维度（控制输入）

%% 4) H∞ 综合
opts = hinfsynOptions('Display','on','Method','ric','RelTol',1e-3);

% 尝试 H∞ 设计，如果失败则尝试其他方法
try
    fprintf('Attempting H-infinity synthesis...\n');
    [K_Hinf_SS, CL, gamma] = hinfsyn(P, nmeas, ncon, opts);  % K: y->v
    fprintf('H-infinity synthesis successful!\n');
catch ME
    fprintf('H-infinity synthesis failed with error: %s\n', ME.message);
    
    % 尝试使用 LQG 方法作为备选
    fprintf('Attempting fallback LQG design...\n');
    try
        % 检查可控性和可观性
        Co = ctrb(P.A, P.B(:,3:4));  % 控制输入部分
        Ob = obsv(P.A, P.C(end-5:end,:));  % 测量输出部分
        fprintf('Controllability rank: %d/%d\n', rank(Co), size(P.A,1));
        fprintf('Observability rank: %d/%d\n', rank(Ob), size(P.A,1));
        
        % 简单的 LQG 设计
        Q = eye(size(P.A,1));
        R = eye(2);
        K_Hinf_SS = lqr(P.A, P.B(:,3:4), Q, R);
        K_Hinf_SS = -K_Hinf_SS;  % 负反馈
        gamma = NaN;
        CL = [];
        fprintf('LQG fallback design completed.\n');
    catch ME2
        fprintf('LQG fallback also failed: %s\n', ME2.message);
        rethrow(ME);  % 重新抛出原始错误
    end
end

%% ===== 5) 基本验证 =====
if ~isnan(gamma)
    fprintf('Achieved H-infinity gamma = %.4f\n', gamma);
    if ~isempty(CL)
        [peak,~] = hinfnorm(CL);
        fprintf('hinfnorm(CL) = %.4f\n', peak);  % 应接近 gamma
    end
else
    fprintf('Using LQG controller (gamma not applicable)\n');
end

% 显示控制器信息
if ~isempty(K_Hinf_SS)
    fprintf('Controller K size: %dx%d\n', size(K_Hinf_SS,1), size(K_Hinf_SS,2));
    if isnumeric(K_Hinf_SS)
        fprintf('Controller is static gain matrix\n');
    else
        fprintf('Controller is dynamic system with %d states\n', size(K_Hinf_SS.A,1));
    end
end

% [~,~, K_Hinf, ~] = ssdata(K_Hinf);
% disp(K_Hinf_SS.D);
% K_Hinf = K_Hinf_SS.D;
%% 非解耦H无穷
%% 