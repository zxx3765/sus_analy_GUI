function [rms_values, relative_percentages] = plot_rms_comparison_universal(rms_values, labels, signal_info, config)
%% 通用RMS对比绘图函数 - 基于原有calculate_rms_and_plot_bar优化

% 提取信号信息
signal_name = signal_info{1};
if strcmp(config.language, 'cn')
    signal_label = signal_info{4};
    ylabel_str = '相对RMS (%)';
    title_str = sprintf('%s RMS对比', signal_label);
    xlabel_str = '控制策略';
    % 中文标签
    legend_labels = labels;
else
    signal_label = signal_info{5};
    ylabel_str = 'Relative RMS (%)';
    title_str = sprintf('%s RMS Comparison', signal_label);
    xlabel_str = 'Control Strategy';
    % 英文标签 - 需要映射中文标签到英文标签
    legend_labels = convertLabelsToEnglish(labels);
end

% 若指定了数据顺序映射，则在绘图前对数据与标签进行重排
order = 1:length(legend_labels);
if isfield(config, 'data_order_mapping') && ~isempty(config.data_order_mapping)
    dom = config.data_order_mapping;
    n = length(order);
    % 移动到首位
    if isfield(dom, 'first_index') && ~isempty(dom.first_index) && dom.first_index >= 1 && dom.first_index <= n
        fi = dom.first_index;
        order = [fi, setdiff(order, fi, 'stable')];
    end
    % 移动到末位
    if isfield(dom, 'last_index') && ~isempty(dom.last_index) && dom.last_index >= 1 && dom.last_index <= n
        li = dom.last_index;
        % 将 li 移到末尾
        order = [setdiff(order, li, 'stable'), li];
    end
    % 应用到数据与标签
    rms_values = rms_values(order);
    legend_labels = legend_labels(order);
end

% 计算相对RMS值（以第一个为基准）
baseline_rms = rms_values(1);
relative_percentages = (rms_values / baseline_rms) * 100;

% 显示RMS值 (参考原有函数)
disp(rms_values);
fprintf('%.6f\n', rms_values);

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

% 绘制柱状图
bar_handle = bar(relative_percentages);

% 获取柱状图颜色（根据重排后的“最后”位置着色）
last_pos = [];
if isfield(config, 'data_order_mapping') && isfield(config.data_order_mapping, 'last_index')
    try
        % last_index 原本基于原始顺序，重排后需要找到其在新顺序中的位置
        dom = config.data_order_mapping;
        if ~isempty(dom.last_index) && dom.last_index >= 1 && dom.last_index <= length(legend_labels)
            % 在 order 中查找原始 last_index 的现位置
            % 注意：若未设置 order（没有映射），此处按原位
            if exist('order', 'var')
                last_pos = find(order == dom.last_index, 1);
            else
                last_pos = dom.last_index;
            end
        end
    catch
        last_pos = [];
    end
end
bar_colors = get_rms_bar_colors(length(legend_labels), last_pos, config);

% 设置柱状图颜色
bar_handle.FaceColor = 'flat';
bar_handle.CData = bar_colors;

% 设置x轴标签
set(gca, 'XTick', 1:length(legend_labels), 'XTickLabel', legend_labels);

% 优化标签显示 - 防止标签重叠
if length(legend_labels) > 4
    % 当标签较多时，旋转标签以节省空间
    xtickangle(45);
    % 调整标签对齐方式
    set(gca, 'TickLabelInterpreter', 'none');
else
    % 当标签较少时，保持水平显示
    xtickangle(0);
    set(gca, 'TickLabelInterpreter', 'none');
end

% 自动调整标签字体大小以适应标签长度
max_label_length = max(cellfun(@length, legend_labels));
if max_label_length > 10
    label_font_size = max(8, config.plot.font_size - 2);
else
    label_font_size = config.plot.font_size;
end
set(gca, 'FontSize', label_font_size);

% 在柱状图上标注百分比值 (参考原有函数)
for i = 1:length(relative_percentages)
    text(i, relative_percentages(i), sprintf('%.1f%%', relative_percentages(i)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', config.plot.font_size-2);
end

% 设置图形属性
xlabel(xlabel_str, 'FontSize', config.plot.font_size);
ylabel(ylabel_str, 'FontSize', config.plot.font_size);
% title(title_str, 'FontSize', config.plot.font_size);  % 注释掉标题，与原函数一致
grid on;

% 保存图形
if config.save_plots
    filename = sprintf('rms_comparison_%s.%s', signal_name, config.plot_format);
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
        fig_filename = sprintf('rms_comparison_%s.fig', signal_name);
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

%% 将中文标签转换为英文标签
function english_labels = convertLabelsToEnglish(chinese_labels)
% 预定义的中英文标签映射
label_mapping = containers.Map(...
    {'被动悬架', '主动悬架', '天棚控制', '天棚观测器', 'PID控制', 'LQR控制', '模糊控制', '神经网络'}, ...
    {'Passive', 'Active', 'Skyhook', 'Skyhook Observer', 'PID', 'LQR', 'Fuzzy', 'Neural Network'});

english_labels = chinese_labels; % 默认使用原始标签

% 尝试映射每个标签
for i = 1:length(chinese_labels)
    if isKey(label_mapping, chinese_labels{i})
        english_labels{i} = label_mapping(chinese_labels{i});
    end
end
end
