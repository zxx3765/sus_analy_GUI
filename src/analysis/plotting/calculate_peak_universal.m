function [peak_values, relative_percentages] = calculate_peak_universal(sig_mat, ~, ~)
%% 通用峰值计算函数（不区分正负，取绝对值最大值）
% 输入:
%   sig_mat: [N x M]，N为时间点，M为数据集数量
% 输出:
%   peak_values: 各数据集的峰值 max(abs(x(t)))
%   relative_percentages: 相对第一个数据集的百分比

% 逐列计算峰值（最大绝对值）
peak_values = max(abs(sig_mat), [], 1);

% 调试输出
disp(peak_values);
fprintf('%.6f\n', peak_values);

% 以第一个为基准计算相对百分比（防止除零）
baseline = peak_values(1);
if baseline == 0
    relative_percentages = 100 * ones(size(peak_values));
else
    relative_percentages = (peak_values / baseline) * 100;
end

end
