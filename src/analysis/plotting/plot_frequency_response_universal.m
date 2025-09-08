function [Mag_matrix, f_freq] = plot_frequency_response_universal(signal_data, road_data, labels, signal_info, config)
%% 通用频率响应绘图函数 - 基于原有plot_frqe_mag_labels优化
% 输入参数:
%   signal_data: 信号数据矩阵 (n_samples x n_datasets)
%   road_data: 路面激励数据矩阵 (n_samples x n_datasets)  
%   labels: 数据标签
%   signal_info: 信号信息 {name, source, index, cn_label, en_label, unit}
%   config: 配置结构体
%
% 输出参数:
%   Mag_matrix: 幅值矩阵 (n_datasets x n_freq)
%   f_freq: 频率向量

% 提取信号信息
signal_name = signal_info{1};
if strcmp(config.language, 'cn')
    signal_label = signal_info{4};
    ylabel_str = '幅值 (dB)';
    xlabel_str = '频率 (Hz)';
    title_str = sprintf('%s频率响应', signal_label);
    % 中文标签
    legend_labels = labels;
else
    signal_label = signal_info{5};
    ylabel_str = 'Magnitude (dB)';
    xlabel_str = 'Frequency (Hz)';
    title_str = sprintf('%s Frequency Response', signal_label);
    % 英文标签 - 需要映射中文标签到英文标签
    legend_labels = convertLabelsToEnglish(labels);
end

% 获取信号长度并智能设置参数
signal_length = size(signal_data, 1);
fprintf('  信号长度: %d 样本\n', signal_length);

% 根据信号长度智能调整参数
if signal_length >= 8192
    % 长信号，使用原有的高精度参数
    nfft = 4096 * 2;
    window = hanning(nfft);
    fs = 1000;
    numoverlap = nfft * 3/4;
    fprintf('  使用高精度参数 (nfft=%d)\n', nfft);
elseif signal_length >= 4096
    % 中等长度信号
    nfft = 4096;
    window = hanning(nfft);
    fs = 1000;
    numoverlap = nfft * 3/4;
    fprintf('  使用中等精度参数 (nfft=%d)\n', nfft);
else
    % 短信号，使用保守参数
    nfft = 2^nextpow2(signal_length/4); % 确保窗口长度合理
    nfft = max(nfft, 256); % 最小窗口长度
    nfft = min(nfft, signal_length); % 不超过信号长度
    window = hanning(nfft);
    fs = 1000;
    numoverlap = floor(nfft * 1/2); % 减少重叠以适应短信号
    fprintf('  使用适配短信号参数 (nfft=%d)\n', nfft);
end

% 频率范围设置 (参考原有函数，但根据采样率调整)
xMin = 0.4;
xMax = min(25, fs/2); % 不超过奈奎斯特频率
nPoints = 100;

% 根据信号长度调整频率分辨率
if signal_length < 2000
    nPoints = 50; % 短信号用较少的频率点
end

logX = linspace(log10(1.5), log10(xMax), nPoints-10);
f = [linspace(xMin, 1.5, 15), 10.^logX];

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
        order = [setdiff(order, li, 'stable'), li];
    end
    % 应用到数据与标签
    signal_data = signal_data(:, order);
    road_data = road_data(:, order);
    labels = labels(order);
    legend_labels = legend_labels(order);
end

% 初始化结果矩阵
Mag_matrix = zeros(length(legend_labels), length(f));

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



% 计算并绘制每个数据集的频率响应
for i = 1:size(signal_data, 2)
    % 提取信号和路面输入
    sig = signal_data(:,i);
    xr = road_data(:,i);
    
    try
        % 计算传递函数 (使用原有函数的方法)
        [Txy, f_freq] = tfestimate(xr, sig, window, numoverlap, f, fs);
        
        % 转换为dB
        Mag_dB = 20*log10(abs(Txy));
        
        % 检查结果是否有效
        if any(~isfinite(Mag_dB))
            fprintf('    警告: 数据集 %d 包含无效值，使用备用方法\n', i);
            % 使用简单的FFT方法作为备用
            [Pxx, f_freq] = pwelch(sig, window, numoverlap, f, fs);
            [Pxy, ~] = pwelch(xr, window, numoverlap, f, fs);
            H = Pxy ./ Pxx;
            Mag_dB = 20*log10(abs(H));
        end
        
    catch ME
        fprintf('    警告: tfestimate失败，使用备用方法: %s\n', ME.message);
        % 使用更简单的方法
        try
            [Pxx, f_freq] = pwelch(sig, [], [], f, fs);
            [Pxy, ~] = pwelch(xr, [], [], f, fs);
            H = Pxy ./ (Pxx + eps); % 添加小的常数避免除零
            Mag_dB = 20*log10(abs(H));
        catch ME2
            fprintf('    错误: 所有方法都失败了: %s\n', ME2.message);
            % 生成虚拟数据以避免崩溃
            Mag_dB = zeros(size(f));
            f_freq = f;
        end
    end
    
    % 存储结果
    Mag_matrix(i,:) = Mag_dB;
    
    % 绘制（使用角色映射的样式）
    semilogx(f_freq, Mag_dB, line_styles{i}, ...
             'LineWidth', line_widths(i), ...
             'DisplayName', legend_labels{i}, ...
             'Color', colors(i,:), ...
             'Marker', 'none');
    hold on;
end

% 添加参考线
if ~isempty(config.plot.reference_lines)
    for ref_freq = config.plot.reference_lines
        if ref_freq <= xMax % 只添加在频率范围内的参考线
            xline(ref_freq, '--', 'Color', [0.5 0.5 0.5], 'LineWidth', 1.5, ...
                  'HandleVisibility', 'off');
        end
    end
end

% 设置图形属性 (参考原有函数)
xlim([xMin, xMax]);
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
    filename = sprintf('freq_response_%s.%s', signal_name, config.plot_format);
    save_path = fullfile(config.output_folder, filename);
    
    % 调试信息
    fprintf('  保存图形: %s\n', filename);
    fprintf('  保存路径: %s\n', save_path);
    fprintf('  输出文件夹: %s\n', config.output_folder);
    fprintf('  文件夹存在: %s\n', mat2str(exist(config.output_folder, 'dir')));
    
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
        fig_filename = sprintf('freq_response_%s.fig', signal_name);
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
