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

% 计算最终顺序：先按 data_order_list 重排，再将 first/last（原始索引）移到首/末
order = 1:length(legend_labels);
if isfield(config, 'data_order_list') && ~isempty(config.data_order_list)
    ord = config.data_order_list(:)';
    ord = unique(ord, 'stable');
    ord = ord(ord>=1 & ord<=length(order));
    rest = setdiff(order, ord, 'stable');
    order = [ord, rest];
end

if isfield(config, 'data_order_mapping') && ~isempty(config.data_order_mapping)
    dom = config.data_order_mapping;
    % 注意：dom.*_index 基于原始数据索引，这里应将对应元素移动到当前order的首/末
    if isfield(dom, 'first_index') && ~isempty(dom.first_index)
        fi_val = dom.first_index; % 原始索引值
        if any(order == fi_val)
            order = [fi_val, setdiff(order, fi_val, 'stable')];
        end
    end
    if isfield(dom, 'last_index') && ~isempty(dom.last_index)
        li_val = dom.last_index; % 原始索引值
        if any(order == li_val)
            order = [setdiff(order, li_val, 'stable'), li_val];
        end
    end
end

% 应用最终顺序到数据与标签
signal_data = signal_data(:, order);
labels = labels(order);
legend_labels = legend_labels(order);

% 获取图形大小设置
if isfield(config, 'plot') && isfield(config.plot, 'figure_size')
    figure_size = config.plot.figure_size;
else
    figure_size = [800, 600];  % 默认大小
end

% 创建新图窗
fig_handle = figure('Position', [100, 100, figure_size]);

% 设置打印属性以避免剪切警告
set(fig_handle, 'PaperType', 'A4');
set(fig_handle, 'PaperOrientation', 'landscape');
set(fig_handle, 'PaperUnits', 'normalized');
set(fig_handle, 'PaperPosition', [0 0 1 1]);

hold on;

% 获取简化的数据样式映射（重排后将 first/last 映射到 1 和 n）
dom_after = struct();
if isfield(config, 'data_order_mapping') && ~isempty(config.data_order_mapping)
    dom_orig = config.data_order_mapping;
    if isfield(dom_orig, 'first_index') && ~isempty(dom_orig.first_index)
        dom_after.first_index = 1; % 重排后，该数据已位于首位
    end
    if isfield(dom_orig, 'last_index') && ~isempty(dom_orig.last_index)
        dom_after.last_index = length(legend_labels); % 重排后，该数据已位于末位
    end
end
if isempty(fieldnames(dom_after))
    dom_after = [];
end
[line_styles, colors, line_widths] = get_simple_data_styles(legend_labels, dom_after, config);

% 绘制每个数据集的时域响应
for i = 1:size(signal_data, 2)
    plot(time_vector, signal_data(:,i), line_styles{i}, ...
         'LineWidth', line_widths(i), ...
         'DisplayName', legend_labels{i}, ...
         'Color', colors(i,:), ...
         'Marker', 'none');
end

% 设置图形属性 (参考原有函数)
xlabel(xlabel_str, 'FontSize', config.plot.font_size);
ylabel(ylabel_str, 'FontSize', config.plot.font_size);
% title(title_str, 'FontSize', config.plot.font_size);  % 注释掉标题，与原函数一致

% 应用图例控制
if exist('legend_control', 'file')
    try
        legend_config = legend_control(config, signal_info, labels);
        % 应用预设样式 (如果配置中指定了)
        if isfield(config.plot, 'legend_preset') && ~isempty(config.plot.legend_preset)
            preset_config = legend_style_presets(config.plot.legend_preset, config.language);
            % 合并预设配置和自定义配置
            legend_config = merge_legend_configs(legend_config, preset_config);
        end
    apply_legend_settings(fig_handle, legend_config);
    catch ME
        fprintf('  ⚠ 图例控制出错，使用默认图例: %s\n', ME.message);
        legend('Location', 'best');
    end
else
    % 回退到原有图例设置
    legend('Location', 'best');
end

grid on;

% 保存图形
if config.save_plots
    filename = sprintf('time_response_%s.%s', signal_name, config.plot_format);
    save_path = fullfile(config.output_folder, filename);
    
    % 调试信息
    fprintf('  保存图形: %s\n', filename);
    fprintf('  保存路径: %s\n', save_path);
    % 确保输出目录存在
    if ~exist(config.output_folder, 'dir')
        try
            mkdir(config.output_folder);
            fprintf('  ✓ 已创建输出目录: %s\n', config.output_folder);
        catch ME
            fprintf('  ✗ 创建输出目录失败: %s\n', ME.message);
        end
    end
    
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
