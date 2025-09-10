function [peak_values, relative_percentages] = plot_peak_comparison_universal(peak_values, labels, signal_info, config)
%% 通用峰值对比绘图函数（风格与RMS一致，不区分正负）

% 提取信号信息
signal_name = signal_info{1};
if strcmp(config.language, 'cn')
    signal_label = signal_info{4};
    ylabel_str = '相对峰值 (%)';
    title_str = sprintf('%s 峰值对比', signal_label); %#ok<NASGU>
    xlabel_str = '控制策略';
    legend_labels = labels;
else
    signal_label = signal_info{5}; %#ok<NASGU>
    ylabel_str = 'Relative Peak (%)';
    title_str = sprintf('%s Peak Comparison', signal_label); %#ok<NASGU>
    xlabel_str = 'Control Strategy';
    legend_labels = convertLabelsToEnglish(labels);
end

% 排序：先 data_order_list，再 first/last（原始索引）
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
    if isfield(dom, 'first_index') && ~isempty(dom.first_index)
        fi_val = dom.first_index;
        if any(order == fi_val)
            order = [fi_val, setdiff(order, fi_val, 'stable')];
        end
    end
    if isfield(dom, 'last_index') && ~isempty(dom.last_index)
        li_val = dom.last_index;
        if any(order == li_val)
            order = [setdiff(order, li_val, 'stable'), li_val];
        end
    end
end

% 应用排序
peak_values = peak_values(order);
legend_labels = legend_labels(order);

% 相对百分比
baseline_val = peak_values(1);
if baseline_val == 0
    relative_percentages = 100 * ones(size(peak_values));
else
    relative_percentages = (peak_values / baseline_val) * 100;
end

% 输出
disp(peak_values);
fprintf('%.6f\n', peak_values);

% 图窗设置
figure_size = ifelse(isfield(config, 'plot') && isfield(config.plot, 'figure_size'), ...
                     config.plot.figure_size, [800, 600]);
fig_handle = figure('Position', [100, 100, figure_size]);
set(fig_handle, 'PaperType', 'A4', 'PaperOrientation', 'landscape', ...
                'PaperUnits', 'normalized', 'PaperPosition', [0 0 1 1]);

% 柱状图
bar_handle = bar(relative_percentages);

% 颜色：与RMS一致，仅“最后一个”变色
last_pos = [];
if isfield(config, 'data_order_mapping') && isfield(config.data_order_mapping, 'last_index')
    try
        dom = config.data_order_mapping;
        if ~isempty(dom.last_index)
            last_pos = find(order == dom.last_index, 1);
        end
    catch
        last_pos = [];
    end
end
bar_colors = get_rms_bar_colors(length(legend_labels), last_pos, config);
bar_handle.FaceColor = 'flat';
bar_handle.CData = bar_colors;

% 轴标签 & 字体
set(gca, 'XTick', 1:length(legend_labels), 'XTickLabel', legend_labels);
if length(legend_labels) > 4
    xtickangle(45);
else
    xtickangle(0);
end
set(gca, 'TickLabelInterpreter', 'none');

max_label_length = max(cellfun(@length, legend_labels));
label_font_size = config.plot.font_size - (max_label_length > 10) * 2;
label_font_size = max(8, label_font_size);
set(gca, 'FontSize', label_font_size);

% 数值标注
for i = 1:length(relative_percentages)
    text(i, relative_percentages(i), sprintf('%.1f%%', relative_percentages(i)), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', config.plot.font_size-2);
end

xlabel(xlabel_str, 'FontSize', config.plot.font_size);
ylabel(ylabel_str, 'FontSize', config.plot.font_size);
grid on;

% 保存
if config.save_plots
    filename = sprintf('peak_comparison_%s.%s', signal_name, config.plot_format);
    save_path = fullfile(config.output_folder, filename);
    % 确保输出目录存在
    try
        if ~exist(config.output_folder, 'dir')
            mkdir(config.output_folder);
        end
    catch
    end
    fprintf('  保存图形: %s\n', filename);
    fprintf('  保存路径: %s\n', save_path);
    try
        figure(fig_handle);
        switch config.plot_format
            case 'png'
                print(fig_handle, save_path, '-dpng', sprintf('-r%d', config.figure_dpi));
            case 'eps'
                print(fig_handle, save_path, '-depsc2', '-bestfit');
            case 'pdf'
                print(fig_handle, save_path, '-dpdf', '-bestfit');
        end
        if exist(save_path, 'file')
            file_info = dir(save_path);
            fprintf('  ✓ 文件已保存: %s (%.1f KB)\n', filename, file_info.bytes/1024);
        else
            fprintf('  ✗ 文件保存失败: %s\n', filename);
        end
    catch ME
        fprintf('  ✗ 保存出错: %s\n', ME.message);
    end

    if config.save_fig_files
        fig_filename = sprintf('peak_comparison_%s.fig', signal_name);
        fig_save_path = fullfile(config.output_folder, fig_filename);
        try
            if ~exist(config.output_folder, 'dir')
                mkdir(config.output_folder);
            end
        catch
        end
        try
            savefig(fig_handle, fig_save_path);
            fprintf('  ✓ .fig文件已保存: %s\n', fig_filename);
        catch ME
            fprintf('  ✗ .fig文件保存失败: %s\n', ME.message);
        end
    end
end

if config.close_figures
    close(fig_handle);
    fprintf('  ✓ 图窗已关闭\n');
end

end

function english_labels = convertLabelsToEnglish(chinese_labels)
label_mapping = containers.Map(...
    {'被动悬架', '主动悬架', '天棚控制', '天棚观测器', 'PID控制', 'LQR控制', '模糊控制', '神经网络'}, ...
    {'Passive', 'Active', 'Skyhook', 'Skyhook Observer', 'PID', 'LQR', 'Fuzzy', 'Neural Network'});

english_labels = chinese_labels;
for i = 1:length(chinese_labels)
    if isKey(label_mapping, chinese_labels{i})
        english_labels{i} = label_mapping(chinese_labels{i});
    end
end
end

% 内联简易 ifelse
function out = ifelse(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end
