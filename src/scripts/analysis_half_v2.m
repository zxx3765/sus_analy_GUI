%% analysis_half_v2.m - 优化版半车仿真结果分析脚本
% 这个脚本是原analysis_half.m的升级版本
% 使用新的通用分析工具，但保持相似的调用方式

%% 使用说明
% 1. 确保工作空间中有以下变量：
%    - out_passive, out_sk_ob, out_sk (或其他仿真结果变量)
% 2. 直接运行此脚本即可完成分析
% 3. 结果将保存在 'results' 文件夹中

%% 检查必要的数据是否存在
fprintf('正在检查数据可用性...\n');

% 检查可能的数据变量名
possible_vars = {'out_passive', 'out_sk_ob', 'out_sk', 'out_skyhook', 'out_active'};
available_data = {};
available_labels = {};

for i = 1:length(possible_vars)
    var_name = possible_vars{i};
    if evalin('base', sprintf('exist(''%s'', ''var'')', var_name))
        available_data{end+1} = evalin('base', var_name);
        % 创建更友好的标签
        switch var_name
            case 'out_passive'
                available_labels{end+1} = '被动悬架';
            case 'out_sk_ob'
                available_labels{end+1} = '天棚观测器';
            case {'out_sk', 'out_skyhook'}
                available_labels{end+1} = '天棚控制';
            case 'out_active'
                available_labels{end+1} = '主动悬架';
            otherwise
                available_labels{end+1} = strrep(var_name, 'out_', '');
        end
        fprintf('  找到数据: %s -> %s\n', var_name, available_labels{end});
    end
end

if isempty(available_data)
    error('未找到仿真数据！请确保工作空间中有以下变量之一: %s', ...
          strjoin(possible_vars, ', '));
end

fprintf('共找到 %d 组数据\n\n', length(available_data));

%% 快速配置
% 用户可以在这里修改配置，而不需要深入了解配置文件细节
LANGUAGE = 'cn';                    % 'cn' 或 'en'
SAVE_PLOTS = true;                  % 是否保存图片
USE_TIMESTAMP_FOLDER = true;        % 是否使用时间戳文件夹
OUTPUT_FOLDER = '';                 % 自定义输出文件夹（留空则使用时间戳）
PLOT_FORMAT = 'png';               % 图片格式: 'png', 'eps', 'pdf'
REFERENCE_FREQUENCIES = [1, 10];   % 参考频率线 (Hz)

% 分析开关 - 可以根据需要开启/关闭
ENABLE_FREQUENCY_ANALYSIS = true;   % 频率分析
ENABLE_TIME_ANALYSIS = true;        % 时域分析  
ENABLE_RMS_ANALYSIS = true;         % RMS对比分析
ENABLE_STATISTICAL_ANALYSIS = true; % 统计分析

%% 创建配置
% 使用新的 quick_config 函数来处理时间戳文件夹
if USE_TIMESTAMP_FOLDER || isempty(OUTPUT_FOLDER)
    config = quick_config('half', LANGUAGE, SAVE_PLOTS);  % 自动使用时间戳
else
    config = quick_config('half', LANGUAGE, SAVE_PLOTS, OUTPUT_FOLDER);  % 使用指定文件夹
end

% 应用其他用户设置
config.plot_format = PLOT_FORMAT;
config.plot.reference_lines = REFERENCE_FREQUENCIES;

% 分析类型设置
config.analysis.frequency_response = ENABLE_FREQUENCY_ANALYSIS;
config.analysis.time_domain = ENABLE_TIME_ANALYSIS;
config.analysis.rms_comparison = ENABLE_RMS_ANALYSIS;
config.analysis.statistical = ENABLE_STATISTICAL_ANALYSIS;

% 绘图设置优化
config.plot.line_width = 2;
config.plot.font_size = 14;
config.plot.figure_size = [1000, 700];
config.figure_dpi = 300;

%% 执行分析
fprintf('开始执行悬架分析...\n');
fprintf('配置: %s语言, %d组数据, 输出到 "%s" 文件夹\n', ...
        upper(LANGUAGE), length(available_data), config.output_folder);

try
    % 调用通用分析工具
    suspension_analysis_tool(available_data, available_labels, 'Config', config);
    
    fprintf('\n=== 分析完成 ===\n');
    if SAVE_PLOTS
        fprintf('所有结果已保存至: %s\n', fullfile(pwd, config.output_folder));
        
        % 显示生成的文件
        if exist(config.output_folder, 'dir')
            files = dir(fullfile(config.output_folder, '*'));
            files = files(~[files.isdir]); % 只显示文件
            fprintf('\n生成的文件:\n');
            for i = 1:length(files)
                fprintf('  - %s\n', files(i).name);
            end
        end
    end
    
catch ME
    fprintf('\n=== 分析过程中出现错误 ===\n');
    fprintf('错误信息: %s\n', ME.message);
    fprintf('错误位置: %s (第%d行)\n', ME.stack(1).file, ME.stack(1).line);
    
    % 提供故障排除建议
    fprintf('\n故障排除建议:\n');
    fprintf('1. 检查数据格式是否正确\n');
    fprintf('2. 确保所有必要的函数文件都在MATLAB路径中\n');
    fprintf('3. 检查输出文件夹权限\n');
    fprintf('4. 验证数据变量是否包含必需的字段 (tout, y_bus, xr, real_x_bus)\n');
end

%% 数据验证辅助函数 (调试用)
function validate_data_structure(data, label)
    fprintf('\n验证数据结构: %s\n', label);
    required_fields = {'tout', 'y_bus', 'xr', 'real_x_bus'};
    
    for i = 1:length(required_fields)
        field = required_fields{i};
        if isfield(data, field)
            field_size = size(data.(field));
            fprintf('  ✓ %s: %dx%d\n', field, field_size(1), field_size(2));
        else
            fprintf('  ✗ 缺失字段: %s\n', field);
        end
    end
end

%% 快速验证所有数据 (可选，用于调试)
if false % 将此改为 true 来启用数据验证
    fprintf('\n=== 数据结构验证 ===\n');
    for i = 1:length(available_data)
        validate_data_structure(available_data{i}, available_labels{i});
    end
end