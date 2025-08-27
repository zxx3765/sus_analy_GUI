function [rms_values, relative_percentages] = calculate_rms(sig_mat)
% 计算信号的均方根值并绘制柱状图，以第一个信号的RMS为基准计算相对百分比
% sig_mat: 信号矩阵，每一列代表一个信号
% labels: 每个信号的标签
% pic_text: 用于图表的文本信息，包括x轴标签、y轴标签和标题

    % 计算每个信号的均方根值
    rms_values = sqrt(mean(sig_mat.^2, 1)); % 沿每一列计算RMS
    disp(rms_values);
    fprintf('%.6f\n', rms_values);
    % 以第一个信号的RMS为基准，计算其他信号的相对百分比
    baseline_rms = rms_values(1); % 第一个信号的RMS值
    relative_percentages = (rms_values / baseline_rms) * 100; % 计算相对百分比
end
 
