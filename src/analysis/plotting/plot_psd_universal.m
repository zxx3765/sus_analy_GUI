function [PSD_matrix, f_freq] = plot_psd_universal(signal_data, labels, signal_info, config)
%% 通用功率谱密度(PSD)绘图函数
% 输入参数:
%   signal_data: 信号数据矩阵 (n_samples x n_datasets)
%   labels: 数据标签
%   signal_info: 信号信息 {name, source, index, cn_label, en_label, unit}
%   config: 配置结构体
%
% 输出参数:
%   PSD_matrix: 功率谱密度矩阵 (n_datasets x n_freq)
%   f_freq: 频率向量

% 提取信号信息
signal_name = signal_info{1};
if strcmp(config.language, 'cn')
    signal_label = signal_info{4};
    ylabel_str = '功率谱密度 (dB/Hz)';
    xlabel_str = '频率 (Hz)';
    title_str = sprintf('%s功率谱密度', signal_label);
    legend_labels = labels;
else
    signal_label = signal_info{5};
    ylabel_str = 'Power Spectral Density (dB/Hz)';
    xlabel_str = 'Frequency (Hz)';
    title_str = sprintf('%s Power Spectral Density', signal_label);
    legend_labels = convertLabelsToEnglish(labels);
end

% 获取信号长度并智能设置参数
signal_length = size(signal_data, 1);
fprintf('  信号长度: %d 样本\n', signal_length);

% 根据信号长度智能调整参数
if signal_length >= 8192
    nfft = 4096 * 2;
    window = hanning(nfft);
    fs = 1000;
    numoverlap = nfft * 3/4;
    fprintf('  使用高精度参数 (nfft=%d)\n', nfft);
elseif signal_length >= 4096
    nfft = 4096;
    window = hanning(nfft);
    fs = 1000;
    numoverlap = nfft * 3/4;
    fprintf('  使用中等精度参数 (nfft=%d)\n', nfft);
else
    nfft = 2^nextpow2(signal_length/4);
    nfft = max(nfft, 256);
    nfft = min(nfft, signal_length);
    window = hanning(nfft);
    fs = 1000;
    numoverlap = floor(nfft * 1/2);
    fprintf('  使用适配短信号参数 (nfft=%d)\n', nfft);
end

% 频率范围设置
xMin = 0.4;
xMax = min(25, fs/2);
nPoints = 100;

if signal_length < 2000
    nPoints = 50;
end

logX = linspace(log10(1.5), log10(xMax), nPoints-10);
f = [linspace(xMin, 1.5, 15), 10.^logX];

% 计算最终顺序
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

% 应用顺序
signal_data = signal_data(:, order);
labels = labels(order);
legend_labels = legend_labels(order);

% 初始化结果矩阵
PSD_matrix = zeros(length(legend_labels), length(f));

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
fig_handle = figure('Name', fig_name, 'Position', [100, 100, figure_size]);
set(fig_handle, 'PaperType', 'A4');
set(fig_handle, 'PaperOrientation', 'landscape');
set(fig_handle, 'PaperUnits', 'normalized');
set(fig_handle, 'PaperPosition', [0 0 1 1]);

% 获取样式映射
dom_after = struct();
if isfield(config, 'data_order_mapping') && ~isempty(config.data_order_mapping)
    dom_orig = config.data_order_mapping;
    if isfield(dom_orig, 'first_index') && ~isempty(dom_orig.first_index)
        dom_after.first_index = 1;
    end
    if isfield(dom_orig, 'last_index') && ~isempty(dom_orig.last_index)
        dom_after.last_index = length(legend_labels);
    end
end
if isempty(fieldnames(dom_after))
    dom_after = [];
end
[line_styles, colors, line_widths] = get_simple_data_styles(legend_labels, dom_after, config);

% 计算并绘制每个数据集的PSD
for i = 1:size(signal_data, 2)
    sig = signal_data(:,i);

    try
        % 计算功率谱密度
        [Pxx, f_freq] = pwelch(sig, window, numoverlap, f, fs);

        % 转换为dB
        PSD_dB = 10*log10(Pxx);

        % 检查结果是否有效
        if any(~isfinite(PSD_dB))
            fprintf('    警告: 数据集 %d 包含无效值\n', i);
            PSD_dB(~isfinite(PSD_dB)) = -inf;
        end

    catch ME
        fprintf('    警告: pwelch失败: %s\n', ME.message);
        PSD_dB = zeros(size(f));
        f_freq = f;
    end

    % 存储结果
    PSD_matrix(i,:) = PSD_dB;

    % 绘制
    semilogx(f_freq, PSD_dB, line_styles{i}, ...
             'LineWidth', line_widths(i), ...
             'DisplayName', legend_labels{i}, ...
             'Color', colors(i,:), ...
             'Marker', 'none');
    hold on;
end

% 添加参考线
if ~isempty(config.plot.reference_lines)
    for ref_freq = config.plot.reference_lines
        if ref_freq <= xMax
            xline(ref_freq, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, ...
                  'HandleVisibility', 'off');
        end
    end
end

% 设置图形属性
xlim([xMin, xMax]);
xlabel(xlabel_str, 'FontSize', config.plot.font_size);
ylabel(ylabel_str, 'FontSize', config.plot.font_size);

% 应用图例控制
if exist('legend_control', 'file')
    try
        legend_config = legend_control(config, signal_info, labels);
        if isfield(config.plot, 'legend_preset') && ~isempty(config.plot.legend_preset)
            preset_config = legend_style_presets(config.plot.legend_preset, config.language);
            legend_config = merge_legend_configs(legend_config, preset_config);
        end
        apply_legend_settings(fig_handle, legend_config);
    catch ME
        fprintf('  ⚠ 图例控制出错，使用默认图例: %s\n', ME.message);
        legend('Location', 'best');
    end
else
    legend('Location', 'best');
end

grid on;

% 保存图形
if config.save_plots
    filename = sprintf('psd_%s.%s', signal_name, config.plot_format);
    save_path = fullfile(config.output_folder, filename);

    fprintf('  保存图形: %s\n', filename);

    if ~exist(config.output_folder, 'dir')
        mkdir(config.output_folder);
        fprintf('  ✓ 已创建输出目录: %s\n', config.output_folder);
    end

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
        end

    catch ME
        fprintf('  ✗ 保存出错: %s\n', ME.message);
    end

    if config.save_fig_files
        fig_filename = sprintf('psd_%s.fig', signal_name);
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

% 导出绘图数据
if config.save_to_workspace || config.save_mat_files
    plot_data = struct();
    plot_data.PSD_matrix = PSD_matrix;
    plot_data.f_freq = f_freq;

    export_plot_data(plot_data, signal_info, legend_labels, config, 'psd');
end

end
