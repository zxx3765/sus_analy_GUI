function [rms_values, relative_percentages] = calculate_rms_and_plot_bar(sig_mat, labels, pic_text)
% 计算信号的均方根值并绘制柱状图，以第一个信号的RMS为基准计算相对百分比
% sig_mat: 信号矩阵，每一列代表一个信号
% labels: 每个信号的标签
% pic_text: 用于图表的文本信息，包括x轴标签、y轴标签和标题

    [rms_values,relative_percentages] = calculate_rms(sig_mat);

    % 绘制柱状图
    figure;
    bar_handle = bar(relative_percentages); % 获取柱状图的句柄
    
    % 设置柱状图颜色
    colors = lines(length(labels)); % 生成默认颜色矩阵
    for i = 1:length(labels)
        if i == length(labels) % 最后一个信号
            bar_handle.FaceColor = 'flat'; % 允许单独设置颜色
            bar_handle.CData(i, :) = [252,178,175]./255; % 
        else
            bar_handle.FaceColor = 'flat'; % 允许单独设置颜色
            bar_handle.CData(i, :) = [155,223,223]./255; % 使用默认颜色
        end
    end
    
    % 设置x轴标签
    set(gca, 'XTick', 1:length(labels), 'XTickLabel', labels);
    
    % 设置图表标题和轴标签
    xlabel(pic_text{1});
    ylabel(pic_text{2});
    % title(pic_text{3});
    
    % 在柱状图上标注百分比值
    for i = 1:length(relative_percentages)
        text(i, relative_percentages(i), sprintf('%.1f%%', relative_percentages(i)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom');
    end
    
    % 添加网格
    grid on;
end
 
