function plot_time_response_universal(signal_data, time_vector, labels, signal_info, config)
%% 通用时域响应绘图函数 - 基于原有plot_time_labels优化

% 提取信号信息
signal_name = signal_info{1};

% 获取单位信息
if length(signal_info) >= 6
    unit_str = signal_info{6};
else
    unit_str = '';
end

% 确保单位不为空
if isempty(unit_str)
    unit_str = '';
end

if strcmp(config.language, 'cn')
    signal_label = signal_info{4};
    if ~isempty(unit_str)
        ylabel_str = sprintf('%s (%s)', signal_label, unit_str);
    else
        ylabel_str = signal_label;
    end
    xlabel_str = '时间 (s)';
    title_str = sprintf('%s时域响应', signal_label);
    % 中文标签
    legend_labels = labels;
else
    signal_label = signal_info{5};
    if ~isempty(unit_str)
        ylabel_str = sprintf('%s (%s)', signal_label, unit_str);
    else
        ylabel_str = signal_label;
    end
    xlabel_str = 'Time (s)';
    title_str = sprintf('%s Time Response', signal_label);
    % 英文标签 - 需要映射中文标签到英文标签
    legend_labels = convertLabelsToEnglish(labels);
end

% 创建新图窗
fig_handle = figure('Position', [100, 100, config.plot.figure_size]);

% 设置打印属性以避免剪切警告
set(fig_handle, 'PaperType', 'A4');
set(fig_handle, 'PaperOrientation', 'landscape');
set(fig_handle, 'PaperUnits', 'normalized');
set(fig_handle, 'PaperPosition', [0 0 1 1]);

hold on;

% 颜色设置 (参考原有函数)
colors = lines(length(labels));
colors(end,:) = [0,0,0];  % 最后一个设为黑色

% 绘制每个数据集的时域响应 (参考原有函数的线型设置)
for i = 1:size(signal_data, 2)
    if i == 1
        plot(time_vector, signal_data(:,i), '--', 'LineWidth', 1.5, ...
             'DisplayName', legend_labels{i}, 'Color', colors(i,:));
    elseif i == length(legend_labels)
        plot(time_vector, signal_data(:,i), '-', 'LineWidth', 1.5, ...
             'DisplayName', legend_labels{i}, 'Color', colors(i,:));
    else
        plot(time_vector, signal_data(:,i), '-', 'LineWidth', 1.0, ...
             'DisplayName', legend_labels{i}, 'Color', colors(i,:));
    end
end

% 设置图形属性 (参考原有函数)
xlabel(xlabel_str, 'FontSize', config.plot.font_size);
ylabel(ylabel_str, 'FontSize', config.plot.font_size);
% title(title_str, 'FontSize', config.plot.font_size);  % 注释掉标题，与原函数一致
legend('Location', 'best');
grid on;

% 保存图形
if config.save_plots
    filename = sprintf('time_response_%s.%s', signal_name, config.plot_format);
    save_path = fullfile(config.output_folder, filename);
    
    % 调试信息
    fprintf('  保存图形: %s\n', filename);
    fprintf('  保存路径: %s\n', save_path);
    
    try
        % 设置为当前图形以确保正确保存
        figure(fig_handle);
        
        switch config.plot_format
            case 'png'
                print(fig_handle, save_path, '-dpng', sprintf('-r%d', config.figure_dpi));
            case 'eps'
                print(fig_handle, save_path, '-depsc2', '-bestfit');
            case 'pdf'
                print(fig_handle, save_path, '-dpdf', '-bestfit');
        end
        
        % 验证文件是否真的被保存
        if exist(save_path, 'file')
            file_info = dir(save_path);
            fprintf('  ✓ 文件已保存: %s (%.1f KB)\n', filename, file_info.bytes/1024);
        else
            fprintf('  ✗ 文件保存失败: %s\n', filename);
        end
        
    catch ME
        fprintf('  ✗ 保存出错: %s\n', ME.message);
    end
    
    % 保存.fig文件
    if config.save_fig_files
        fig_filename = sprintf('time_response_%s.fig', signal_name);
        fig_save_path = fullfile(config.output_folder, fig_filename);
        
        try
            savefig(fig_handle, fig_save_path);
            fprintf('  ✓ .fig文件已保存: %s\n', fig_filename);
        catch ME
            fprintf('  ✗ .fig文件保存失败: %s\n', ME.message);
        end
    end
end

% 关闭图窗
if config.close_figures
    close(fig_handle);
    fprintf('  ✓ 图窗已关闭\n');
end

end
