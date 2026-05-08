function [weighted_rms_values, rms_values] = calculate_weighted_rms_iso2631(sig_mat, time, config)
    %% ISO2631-1 Wk加权RMS计算函数 (垂直方向)
    % 输入参数:
    %   sig_mat: 信号矩阵，每一列代表一个加速度信号 (m/s^2)
    %   time: 时间向量
    %   config: 配置结构体 (可选，包含language字段)
    % 输出参数:
    %   weighted_rms_values: Wk加权后的RMS值
    %   rms_values: 原始RMS值（未加权）

    if nargin < 3
        config.language = 'cn';
    end

    % 计算采样频率
    dt = mean(diff(time));
    fs = 1/dt;

    num_signals = size(sig_mat, 2);

    % 初始化输出
    weighted_rms_values = zeros(1, num_signals);
    rms_values = zeros(1, num_signals);

    % 对每个信号进行Wk加权和RMS计算
    for i = 1:num_signals
        % 去均值预处理（去除直流分量）
        signal_ac = sig_mat(:,i) - mean(sig_mat(:,i));

        % 原始RMS（去均值后）
        rms_values(i) = sqrt(mean(signal_ac.^2));

        % 应用ISO2631-1 Wk加权滤波
        weighted_signal = iso2631_weighting_filter(signal_ac, fs);

        % 计算加权RMS
        weighted_rms_values(i) = sqrt(mean(weighted_signal.^2));
    end

    % 显示结果
    if strcmp(config.language, 'cn')
        fprintf('ISO2631-1 Wk加权RMS值: ');
    else
        fprintf('ISO2631-1 Wk weighted RMS values: ');
    end
    fprintf('%.6f ', weighted_rms_values);
    fprintf('\n');

end
