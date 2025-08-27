function [rms_values, relative_percentages] = calculate_rms_universal(sig_mat, labels, config)
%% 通用RMS计算函数 - 基于原有calculate_rms优化
% 输入参数:
%   sig_mat: 信号矩阵，每一列代表一个信号
%   labels: 每个信号的标签 
%   config: 配置结构体
% 输出参数:
%   rms_values: 各信号的RMS值
%   relative_percentages: 相对百分比

% 计算每个信号的均方根值 (参考原有函数)
rms_values = sqrt(mean(sig_mat.^2, 1)); % 沿每一列计算RMS

% 显示RMS值 (参考原有函数)
if strcmp(config.language, 'cn')
    fprintf('RMS值: ');
else
    fprintf('RMS values: ');
end
disp(rms_values);
fprintf('%.6f\n', rms_values);

% 以第一个信号的RMS为基准，计算其他信号的相对百分比 (参考原有函数)
baseline_rms = rms_values(1); % 第一个信号的RMS值
relative_percentages = (rms_values / baseline_rms) * 100; % 计算相对百分比

end