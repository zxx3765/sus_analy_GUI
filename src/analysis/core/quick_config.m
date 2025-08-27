function config = quick_config(varargin)
%% 快速配置生成器
% 用于快速生成悬架分析配置，无需了解详细的配置结构
%
% 使用方法:
%   config = quick_config('half', 'cn', true)  % 半车、中文、保存图片
%   config = quick_config('quarter')           % 四分之一车、默认设置
%   config = quick_config('ModelType', 'half', 'Language', 'en', 'SavePlots', false)
%
% 参数说明:
%   位置参数 (按顺序):
%     1. model_type: 'half' 或 'quarter'
%     2. language: 'cn' 或 'en' 
%     3. save_plots: true 或 false
%     4. output_folder: 输出文件夹名称
%
%   名称-值参数对:
%     'ModelType': 模型类型
%     'Language': 语言
%     'SavePlots': 是否保存图片
%     'SaveFigFiles': 是否保存.fig文件
%     'CloseFigures': 保存后是否关闭图窗
%     'OutputFolder': 输出文件夹
%     'UseTimestamp': 是否使用时间戳文件夹 (true/false)
%     'PlotFormat': 图片格式 ('png', 'eps', 'pdf')
%     'RefFreq': 参考频率数组 [freq1, freq2, ...]
%     'FontSize': 字体大小
%     'LineWidth': 线宽
%     'FigSize': 图形尺寸 [width, height]

%% 默认值设置
defaults.model_type = 'half';
defaults.language = 'cn';
defaults.save_plots = true;
defaults.save_fig_files = true;     % 是否保存.fig文件
defaults.close_figures = true;      % 保存后是否关闭图窗
defaults.output_folder = '';  % 空字符串表示自动生成时间戳文件夹
defaults.use_timestamp = true;  % 默认使用时间戳文件夹
defaults.plot_format = 'png';
defaults.ref_freq = [];
defaults.font_size = 12;
defaults.line_width = 1.5;
defaults.fig_size = [800, 600];

%% 简化的参数解析 - 修复strcmpi错误
params = defaults;

% 检查是否为位置参数模式 - 修复参数检测逻辑
is_positional = true;
if nargin > 0
    % 如果任何参数是名称-值对的名称，则为名称-值模式
    name_value_names = {'ModelType', 'Language', 'SavePlots', 'SaveFigFiles', 'CloseFigures', 'OutputFolder', 'UseTimestamp', 'PlotFormat', 'RefFreq', 'FontSize', 'LineWidth', 'FigSize'};
    
    for i = 1:nargin
        if ischar(varargin{i}) || isstring(varargin{i})
            if any(strcmpi(varargin{i}, name_value_names))
                is_positional = false;
                break;
            end
        end
    end
    
    % 特殊情况：如果参数数量超过4个，且包含字符串，很可能是名称-值模式
    if is_positional && nargin > 4
        string_count = sum(cellfun(@(x) ischar(x) || isstring(x), varargin));
        if string_count >= 2 % 至少有2个字符串参数
            is_positional = false;
        end
    end
end

if nargin == 0
    % 无参数，使用默认值
elseif nargin <= 4 && is_positional
    % 位置参数模式
    if nargin >= 1, params.model_type = varargin{1}; end
    if nargin >= 2, params.language = varargin{2}; end
    if nargin >= 3, params.save_plots = varargin{3}; end
    if nargin >= 4, params.output_folder = varargin{4}; end
else
    % 名称-值参数对模式
    p = inputParser;
    addParameter(p, 'ModelType', defaults.model_type, @(x) any(validatestring(x, {'half', 'quarter'})));
    addParameter(p, 'Language', defaults.language, @(x) any(validatestring(x, {'cn', 'en'})));
    addParameter(p, 'SavePlots', defaults.save_plots, @islogical);
    addParameter(p, 'SaveFigFiles', defaults.save_fig_files, @islogical);
    addParameter(p, 'CloseFigures', defaults.close_figures, @islogical);
    addParameter(p, 'OutputFolder', defaults.output_folder, @ischar);
    addParameter(p, 'UseTimestamp', defaults.use_timestamp, @islogical);
    addParameter(p, 'PlotFormat', defaults.plot_format, @(x) any(validatestring(x, {'png', 'eps', 'pdf'})));
    addParameter(p, 'RefFreq', defaults.ref_freq, @isnumeric);
    addParameter(p, 'FontSize', defaults.font_size, @isnumeric);
    addParameter(p, 'LineWidth', defaults.line_width, @isnumeric);
    addParameter(p, 'FigSize', defaults.fig_size, @isnumeric);
    
    parse(p, varargin{:});
    
    params.model_type = p.Results.ModelType;
    params.language = p.Results.Language;
    params.save_plots = p.Results.SavePlots;
    params.save_fig_files = p.Results.SaveFigFiles;
    params.close_figures = p.Results.CloseFigures;
    params.output_folder = p.Results.OutputFolder;
    params.use_timestamp = p.Results.UseTimestamp;
    params.plot_format = p.Results.PlotFormat;
    params.ref_freq = p.Results.RefFreq;
    params.font_size = p.Results.FontSize;
    params.line_width = p.Results.LineWidth;
    params.fig_size = p.Results.FigSize;
end

%% 生成基础配置
config = suspension_analysis_config(params.model_type);

%% 应用用户设置
config.language = params.language;
config.save_plots = params.save_plots;
config.save_fig_files = params.save_fig_files;
config.close_figures = params.close_figures;
config.plot_format = params.plot_format;

% 处理输出文件夹设置
if params.use_timestamp || isempty(params.output_folder)
    % 使用时间戳文件夹
    config.output_folder = get_timestamped_results_folder();
    config.use_timestamp_folder = true;
else
    % 使用用户指定的文件夹
    config.output_folder = params.output_folder;
    config.use_timestamp_folder = false;
    % 创建文件夹（如果不存在）
    if ~exist(config.output_folder, 'dir')
        mkdir(config.output_folder);
        fprintf('创建结果文件夹: %s\n', config.output_folder);
    end
end

% 绘图设置
config.plot.reference_lines = params.ref_freq;
config.plot.font_size = params.font_size;
config.plot.line_width = params.line_width;
config.plot.figure_size = params.fig_size;

%% 显示配置摘要
if nargout == 0 || strcmp(params.language, 'cn')
    fprintf('\n=== 配置摘要 ===\n');
    fprintf('模型类型: %s\n', params.model_type);
    fprintf('界面语言: %s\n', params.language);
    fprintf('保存图片: %s\n', mat2str(params.save_plots));
    fprintf('输出文件夹: %s\n', params.output_folder);
    fprintf('图片格式: %s\n', params.plot_format);
    if ~isempty(params.ref_freq)
        fprintf('参考频率: %s Hz\n', mat2str(params.ref_freq));
    end
    fprintf('字体大小: %d\n', params.font_size);
    fprintf('线宽: %.1f\n', params.line_width);
    fprintf('图形尺寸: %s\n', mat2str(params.fig_size));
    fprintf('==================\n\n');
else
    fprintf('\n=== Configuration Summary ===\n');
    fprintf('Model Type: %s\n', params.model_type);
    fprintf('Language: %s\n', params.language);
    fprintf('Save Plots: %s\n', mat2str(params.save_plots));
    fprintf('Output Folder: %s\n', params.output_folder);
    fprintf('Plot Format: %s\n', params.plot_format);
    if ~isempty(params.ref_freq)
        fprintf('Reference Frequencies: %s Hz\n', mat2str(params.ref_freq));
    end
    fprintf('Font Size: %d\n', params.font_size);
    fprintf('Line Width: %.1f\n', params.line_width);
    fprintf('Figure Size: %s\n', mat2str(params.fig_size));
    fprintf('============================\n\n');
end

%% 生成带时间戳的结果文件夹路径
function output_folder = get_timestamped_results_folder()
    % 生成格式: results/YYYY-MM-DD_HH-MM-SS
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    base_folder = 'results';
    output_folder = fullfile(base_folder, timestamp);
    
    % 不再立即创建文件夹，而是在实际需要时创建
    % 文件夹将在分析工具中创建
end

end
