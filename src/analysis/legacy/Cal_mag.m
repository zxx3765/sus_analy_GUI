function [mag_as, mag_xt] = Cal_mag(Ha_sym_value,Hxt_sym_value)
    [num, den] = numden(Ha_sym_value);  % 获取分子和分母
    H_tf = tf(sym2poly(num), sym2poly(den));
    % 指定频率范围并获取响应
    w = logspace(-1, 2.5, 500); % 频率范围从 0.1 到 100 rad/s
    [mag_as, phase,wout] = bode(H_tf, w);
    % 将幅值和相位数据提取并绘制
    mag_as = squeeze(mag_as);
    
    % 转换为传递函数对象
    [num, den] = numden(Hxt_sym_value);  % 获取分子和分母
    H_tf = tf(sym2poly(num), sym2poly(den));
    [mag_xt, phase,wout] = bode(H_tf, w);
    % 将幅值和相位数据提取并绘制
    mag_xt = squeeze(mag_xt);
end