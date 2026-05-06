function [weighted_rms_values, rms_values] = calculate_weighted_rms_iso2631(sig_mat, time, weighting_types, config)
%% ISO2631-1加权RMS计算函数
% 输入参数:
%   sig_mat: 信号矩阵，每一列代表一个加速度信号 (m/s^2)
%   time: 时间向量
%   weighting_types: 加权类型，字符串或cell数组 ('Wk'或'Wd')
%                    如果是单个字符串，应用于所有信号
%                    如果是cell数组，为每个信号指定加权类型
%   config: 配置结构体 (可选，包含language字段)
% 输出参数:
%   weighted_rms_values: 加权后的RMS值
%   rms_values: 原始RMS值（未加权）

if nargin < 4
    config.language = 'cn';
end

if nargin < 3
    weighting_types = 'Wk';
end

% 计算采样频率
dt = mean(diff(time));
fs = 1/dt;

% 处理加权类型参数
num_signals = size(sig_mat, 2);
if ischar(weighting_types)
    weighting_types = repmat({weighting_types}, 1, num_signals);
end

% 初始化输出
weighted_rms_values = zeros(1, num_signals);
rms_values = zeros(1, num_signals);

% 对每个信号进行加权和RMS计算
for i = 1:num_signals
    % 原始RMS
    rms_values(i) = sqrt(mean(sig_mat(:,i).^2));

    % 应用ISO2631-1加权滤波
    weighted_signal = iso2631_weighting_filter(sig_mat(:,i), fs, weighting_types{i});

    % 计算加权RMS
    weighted_rms_values(i) = sqrt(mean(weighted_signal.^2));
end

% 显示结果
if strcmp(config.language, 'cn')
    fprintf('ISO2631-1加权RMS值: ');
else
    fprintf('ISO2631-1 Weighted RMS values: ');
end
fprintf('%.6f ', weighted_rms_values);
fprintf('\n');

end
