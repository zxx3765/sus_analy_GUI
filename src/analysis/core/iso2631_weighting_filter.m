function weighted_signal = iso2631_weighting_filter(signal, fs,weighting_type)
    %% ISO2631-1 / ISO 8041 标准 Wk 加权滤波器 (垂直方向 z 轴)
    % 输入参数:
    %   signal: 输入加速度信号 (m/s^2)
    %   fs:     采样频率 (Hz)
    % 输出参数:
    %   weighted_signal: 标准加权后的信号

    % 1. 定义 ISO 8041 标准中 Wk 的精确参数
    f1 = 0.4;   Q1 = 1/sqrt(2); w1 = 2*pi*f1;
    f2 = 100;   Q2 = 1/sqrt(2); w2 = 2*pi*f2;
    f3 = 12.5;                  w3 = 2*pi*f3;
    f4 = 12.5;  Q4 = 0.63;      w4 = 2*pi*f4;
    f5 = 2.37;  Q5 = 0.91;      w5 = 2*pi*f5;
    f6 = 3.35;  Q6 = 0.91;      w6 = 2*pi*f6;

    % 2. 构建 s 域连续时间传递函数
    s = tf('s');
    
    % 高通带通滤波 Hh(s)
    Hh = (s^2) / (s^2 + (w1/Q1)*s + w1^2);
    
    % 低通带通滤波 Hl(s)
    Hl = (w2^2) / (s^2 + (w2/Q2)*s + w2^2);
    
    % a-v 转换网络 Ht(s)
    Ht = (1 + s/w3) / (1 + s/(Q4*w4) + (s/w4)^2);
    
    % 向上阶跃网络 Hs(s)
    Hs = ((1 + s/(Q5*w5) + (s/w5)^2) / (1 + s/(Q6*w6) + (s/w6)^2)) * (w5/w6)^2;
    
    % 计算总连续时间传递函数
    H_total = Hh * Hl * Ht * Hs;
    
    % 3. 离散化数字滤波器设计 (双线性变换 Tustin 方法)
    % 将连续时间传递函数转换为离散时间
    H_z = c2d(H_total, 1/fs, 'tustin');
    
    % 提取数字滤波器的分子(b)和分母(a)多项式系数
    [b, a] = tfdata(H_z, 'v');
    
    % 4. 应用零相移滤波 (消除相位畸变)
    weighted_signal = filtfilt(b, a, signal);
end
