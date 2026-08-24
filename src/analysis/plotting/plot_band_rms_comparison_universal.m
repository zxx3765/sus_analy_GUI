function [fig_handle, order] = plot_band_rms_comparison_universal( ...
    band_rms_values, relative_percentages, labels, signal_info, metadata, config)
%% 绘制单个信号的多频带RMS分组柱状图
% 每个信号生成一个图；横轴为频带，每组柱代表不同数据集。

signal_name = signal_info{1};
signal_unit = signal_info{6};
if strcmp(config.language, 'cn')
    signal_label = signal_info{4};
    xlabel_str = '频带';
    if isempty(signal_unit)
        ylabel_str = '频带RMS';
    else
        ylabel_str = sprintf('频带RMS (%s)', signal_unit);
    end
    title_str = sprintf('%s频带RMS对比', signal_label);
    legend_labels = labels;
else
    signal_label = signal_info{5};
    xlabel_str = 'Frequency Band';
    if isempty(signal_unit)
        ylabel_str = 'Band RMS';
    else
        ylabel_str = sprintf('Band RMS (%s)', signal_unit);
    end
    title_str = sprintf('%s Band RMS Comparison', signal_label);
    legend_labels = convertLabelsToEnglish(labels);
end

order = resolve_data_order_universal(numel(legend_labels), config);
band_rms_values = band_rms_values(order, :);
relative_percentages = relative_percentages(order, :);
labels = labels(order);
legend_labels = legend_labels(order);

figure_size = [900, 650];
if isfield(config, 'plot') && isfield(config.plot, 'figure_size')
    figure_size = config.plot.figure_size;
    figure_size(1) = max(figure_size(1), 900);
end

fig_name = title_str;
if isfield(config, 'plot') && isfield(config.plot, 'figure_name_prefix') && ...
        ~isempty(config.plot.figure_name_prefix)
    fig_name = sprintf('%s - %s', config.plot.figure_name_prefix, title_str);
end

fig_handle = figure('Name', fig_name, 'Position', [100, 100, figure_size]);
set(fig_handle, 'PaperType', 'A4', 'PaperOrientation', 'landscape', ...
    'PaperUnits', 'normalized', 'PaperPosition', [0 0 1 1]);

axes_handle = axes(fig_handle); %#ok<LAXES>
bar_handle = bar(axes_handle, band_rms_values', 'grouped');
hold(axes_handle, 'on');

style_mapping = remap_order_mapping(order, config);
[~, colors] = get_simple_data_styles(legend_labels, style_mapping, config);
for dataset_index = 1:numel(bar_handle)
    bar_handle(dataset_index).FaceColor = colors(dataset_index, :);
    bar_handle(dataset_index).DisplayName = legend_labels{dataset_index};
end

band_tick_labels = make_band_tick_labels(metadata.band_names, metadata.ranges_hz);
set(axes_handle, 'XTick', 1:numel(metadata.band_names), ...
    'XTickLabel', band_tick_labels, 'TickLabelInterpreter', 'none');

xlabel(axes_handle, xlabel_str, 'FontSize', config.plot.font_size);
ylabel(axes_handle, ylabel_str, 'FontSize', config.plot.font_size);
grid(axes_handle, 'on');
axes_handle.YGrid = 'on';
axes_handle.XGrid = 'off';
axes_handle.FontSize = config.plot.font_size;

max_value = max(band_rms_values, [], 'all');
if max_value > 0
    ylim(axes_handle, [0, 1.18 * max_value]);
else
    ylim(axes_handle, [0, 1]);
end

show_relative_labels = true;
if isfield(config, 'band_rms') && ...
        isfield(config.band_rms, 'show_relative_labels')
    show_relative_labels = config.band_rms.show_relative_labels;
end
if show_relative_labels
    add_relative_labels(axes_handle, bar_handle, relative_percentages, ...
        config.plot.font_size);
end

apply_band_rms_legend(fig_handle, signal_info, labels, config);

if config.save_plots
    save_band_rms_figure(fig_handle, signal_name, config);
end

if is_config_enabled(config, 'save_to_workspace') || ...
        is_config_enabled(config, 'save_mat_files')
    plot_data = struct();
    plot_data.band_rms_values = band_rms_values;
    plot_data.relative_percentages = relative_percentages;
    plot_data.band_names = metadata.band_names;
    plot_data.ranges_hz = metadata.ranges_hz;
    export_plot_data(plot_data, signal_info, legend_labels, config, 'band_rms');
end

if config.close_figures
    close(fig_handle);
    fprintf('  ✓ 频带RMS图窗已关闭\n');
end

end

function mapping_after_order = remap_order_mapping(order, config)
mapping_after_order = [];
if ~isfield(config, 'data_order_mapping') || ...
        isempty(config.data_order_mapping)
    return;
end

candidate = struct();
mapping = config.data_order_mapping;
if isfield(mapping, 'first_index')
    first_position = find(order == mapping.first_index, 1);
    if ~isempty(first_position)
        candidate.first_index = first_position;
    end
end
if isfield(mapping, 'last_index')
    last_position = find(order == mapping.last_index, 1);
    if ~isempty(last_position)
        candidate.last_index = last_position;
    end
end
if ~isempty(fieldnames(candidate))
    mapping_after_order = candidate;
end
end

function labels = make_band_tick_labels(band_names, ranges_hz)
labels = cell(1, numel(band_names));
for band_index = 1:numel(band_names)
    labels{band_index} = sprintf('%s [%.3g-%.3g Hz]', ...
        band_names{band_index}, ranges_hz(band_index, 1), ...
        ranges_hz(band_index, 2));
end
end

function add_relative_labels(axes_handle, bar_handle, relative_percentages, font_size)
n_datasets = numel(bar_handle);
for dataset_index = 1:n_datasets
    values = relative_percentages(dataset_index, :);
    text_labels = arrayfun(@format_relative_value, values, ...
        'UniformOutput', false);
    rotation = 0;
    if n_datasets > 4
        rotation = 90;
    end
    text(axes_handle, bar_handle(dataset_index).XEndPoints, ...
        bar_handle(dataset_index).YEndPoints, text_labels, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
        'FontSize', max(7, font_size - 3), 'Rotation', rotation, ...
        'Clipping', 'off');
end
end

function label = format_relative_value(value)
if isfinite(value)
    label = sprintf('%.1f%%', value);
else
    label = 'N/A';
end
end

function apply_band_rms_legend(fig_handle, signal_info, labels, config)
if exist('legend_control', 'file') == 2
    try
        legend_config = legend_control(config, signal_info, labels);
        if isfield(config.plot, 'legend_preset') && ...
                ~isempty(config.plot.legend_preset)
            preset_config = legend_style_presets( ...
                config.plot.legend_preset, config.language);
            legend_config = merge_legend_configs(legend_config, preset_config);
        end
        apply_legend_settings(fig_handle, legend_config);
        return;
    catch ME
        fprintf('  ⚠ 频带RMS图例控制出错，使用默认图例: %s\n', ME.message);
    end
end
legend('Location', 'bestoutside');
end

function save_band_rms_figure(fig_handle, signal_name, config)
if ~exist(config.output_folder, 'dir')
    mkdir(config.output_folder);
end

filename = sprintf('band_rms_comparison_%s.%s', ...
    signal_name, config.plot_format);
save_path = fullfile(config.output_folder, filename);
fprintf('  保存频带RMS图形: %s\n', filename);

switch config.plot_format
    case 'png'
        print(fig_handle, save_path, '-dpng', sprintf('-r%d', config.figure_dpi));
    case 'eps'
        print(fig_handle, save_path, '-depsc2', '-bestfit');
    case 'pdf'
        print(fig_handle, save_path, '-dpdf', '-bestfit');
end

if config.save_fig_files
    fig_path = fullfile(config.output_folder, ...
        sprintf('band_rms_comparison_%s.fig', signal_name));
    savefig(fig_handle, fig_path);
end
end

function enabled = is_config_enabled(config, field_name)
enabled = isfield(config, field_name) && logical(config.(field_name));
end
