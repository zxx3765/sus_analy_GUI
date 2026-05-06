function fig = plot_weighted_rms_comparison_iso2631(weighted_rms_values, labels, config)
%% ISO2631-1加权RMS对比图 - 统一格式
% 输入参数:
%   weighted_rms_values: 加权RMS值
%   labels: 信号标签
%   config: 配置结构体
% 输出参数:
%   fig: 图形句柄

if nargin < 3
    config.language = 'cn';
end

% 计算相对RMS值（以第一个为基准）
baseline_rms = weighted_rms_values(1);
relative_percentages = (weighted_rms_values / baseline_rms) * 100;

% 设置标签和标题
if strcmp(config.language, 'cn')
    ylabel_str = '相对加权RMS (%)';
    title_str = 'ISO2631-1加权RMS对比';
    xlabel_str = '控制策略';
else
    ylabel_str = 'Relative Weighted RMS (%)';
    title_str = 'ISO2631-1 Weighted RMS Comparison';
    xlabel_str = 'Control Strategy';
end

% 获取图形大小设置
if isfield(config, 'plot') && isfield(config.plot, 'figure_size')
    figure_size = config.plot.figure_size;
else
    figure_size = [800, 600];
end

% 构建窗口标题
if isfield(config, 'plot') && isfield(config.plot, 'figure_name_prefix') && ~isempty(config.plot.figure_name_prefix)
    fig_name = sprintf('%s - %s', config.plot.figure_name_prefix, title_str);
else
    fig_name = title_str;
end

% 创建新图窗
fig = figure('Name', fig_name, 'Position', [100, 100, figure_size]);

% 设置打印属性
set(fig, 'PaperType', 'A4');
set(fig, 'PaperOrientation', 'landscape');
set(fig, 'PaperUnits', 'normalized');
set(fig, 'PaperPosition', [0 0 1 1]);

% 绘制柱状图
bar_handle = bar(relative_percentages);

% 获取柱状图颜色
bar_colors = get_rms_bar_colors(length(labels), [], config);

% 设置柱状图颜色
bar_handle.FaceColor = 'flat';
bar_handle.CData = bar_colors;

% 设置x轴标签
set(gca, 'XTick', 1:length(labels), 'XTickLabel', labels);

% 优化标签显示
if length(labels) > 4
    xtickangle(45);
else
    xtickangle(0);
end
set(gca, 'TickLabelInterpreter', 'none');

% 自动调整标签字体大小
max_label_length = max(cellfun(@length, labels));
if isfield(config, 'plot') && isfield(config.plot, 'font_size')
    base_font_size = config.plot.font_size;
else
    base_font_size = 10;
end

if max_label_length > 10
    label_font_size = max(8, base_font_size - 2);
else
    label_font_size = base_font_size;
end
set(gca, 'FontSize', label_font_size);

% 在柱状图上标注百分比值
for i = 1:length(relative_percentages)
    text(i, relative_percentages(i), sprintf('%.1f%%', relative_percentages(i)), ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', base_font_size-2);
end

% 设置图形属性
xlabel(xlabel_str, 'FontSize', base_font_size);
ylabel(ylabel_str, 'FontSize', base_font_size);
grid on;

% 保存图形
if isfield(config, 'save_plots') && config.save_plots
    filename_fig = 'ISO2631_weighted_rms.fig';
    filename_img = sprintf('ISO2631_weighted_rms.%s', config.plot_format);
    save_path_fig = fullfile(config.output_folder, filename_fig);
    save_path_img = fullfile(config.output_folder, filename_img);

    try
        % 保存.fig格式
        savefig(fig, save_path_fig);

        % 保存图像格式
        switch config.plot_format
            case 'png'
                print(fig, save_path_img, '-dpng', sprintf('-r%d', config.figure_dpi));
            case 'eps'
                print(fig, save_path_img, '-depsc2', '-bestfit');
            case 'pdf'
                print(fig, save_path_img, '-dpdf', '-bestfit');
        end
    catch ME
        warning('ISO2631图形保存失败: %s', ME.message);
    end
end

end
