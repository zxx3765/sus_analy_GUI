function config = suspension_analysis_config(model_type)
%% 悬架分析通用配置文件
% 输入参数: 
%   model_type: 'half' (半车模型) 或 'quarter' (四分之一车模型)
% 输出: 配置结构体

if nargin < 1
    model_type = 'half'; % 默认为半车模型
end

%% 通用配置
config.model_type = model_type;
config.save_plots = true;           % 是否保存图片
config.save_fig_files = true;       % 是否保存.fig文件
config.close_figures = true;        % 保存后是否关闭图窗
config.plot_format = 'png';         % 图片格式: 'png', 'eps', 'pdf'
config.figure_dpi = 300;           % 图片分辨率
config.use_timestamp_folder = true; % 是否使用时间戳文件夹
config.output_folder = 'results';   % 默认基础文件夹 (会被quick_config覆盖)

%% 分析类型开关
config.analysis.frequency_response = true;   % 频率响应分析
config.analysis.time_domain = true;          % 时域分析
config.analysis.rms_comparison = true;       % RMS对比分析
config.analysis.statistical = true;          % 统计分析

%% 绘图配置
config.plot.line_width = 1.5;
config.plot.font_size = 12;
config.plot.figure_size = [800, 600];
config.plot.reference_lines = [];  % 参考线频率，如 [11, 25]

%% 语言配置 ('cn' 或 'en')
config.language = 'cn';

%% 根据模型类型设置具体配置
switch lower(model_type)
    case 'half'
        config = set_half_car_config(config);
    case 'quarter'
        config = set_quarter_car_config(config);
    otherwise
        error('不支持的模型类型: %s', model_type);
end

end

%% 半车模型配置
function config = set_half_car_config(config)

% 数据字段映射配置
config.data_fields.time = 'tout';
config.data_fields.outputs = 'y_bus';      % 系统输出
config.data_fields.road_input = 'xr';      % 路面输入
config.data_fields.states = 'real_x_bus';  % 真实状态
config.data_fields.body_state_bus = 'body_state';  %车身状态
config.data_fields.unsprung_state_bus = 'unsprung_state';  %簧载质量状态

% 输出信号索引映射 (基于y_bus)
config.signals.front_sprung_acc = 1;      % 前簧载质量加速度
config.signals.rear_sprung_acc = 2;       % 后簧载质量加速度
config.signals.front_rel_vel = 3;         % 前悬架相对速度
config.signals.rear_rel_vel = 4;          % 后悬架相对速度
config.signals.front_unsprung_acc = 5;    % 前非簧载质量加速度
config.signals.rear_unsprung_acc = 6;     % 后非簧载质量加速度
config.signals.body_acc = 7;              % 车身质心加速度
config.signals.pitch_acc = 8;             % 俯仰角加速度

% 状态信号索引映射 (基于real_x_bus)
config.states.front_tire_def = 1;         % 前轮胎变形
config.states.rear_tire_def = 2;          % 后轮胎变形
config.states.front_susp_def = 3;         % 前悬架变形
config.states.rear_susp_def = 4;          % 后悬架变形

% 路面输入索引映射
config.road.front_input = 1;              % 前轮路面输入
config.road.rear_input = 2;               % 后轮路面输入

% 簧上状态信号索引
config.body_state.xs = 1;              %车身垂向位移
config.body_state.vs = 2;              %车身垂向速度
config.body_state.pitch = 3;              %车身俯仰角
config.body_state.vpitch = 4;              %车身俯仰角速度

% 分析信号配置
config.analysis_signals = {
    % {信号名称, 数据来源, 索引, 中文标签, 英文标签, 单位}
    {'front_sprung_acc', 'outputs', config.signals.front_sprung_acc, '前簧载质量加速度', 'Front Sprung Mass Acceleration', 'm/s²'};
    {'rear_sprung_acc', 'outputs', config.signals.rear_sprung_acc, '后簧载质量加速度', 'Rear Sprung Mass Acceleration', 'm/s²'};
    {'body_acc', 'outputs', config.signals.body_acc, '车身质心加速度', 'Body Center Acceleration', 'm/s²'};
    {'body_x', 'outputs', config.signals.body_acc, '车身质心位移', 'Body Center Displacement', 'm'};
    {'body_v', 'outputs', config.signals.body_acc, '车身质心速度', 'Body Center Velocity', 'm/s'};
    {'pitch_acc', 'outputs', config.states.front_susp_def, '车身俯仰角加速度', 'Body Pitch Acceleration', 'rad/s²'};
    {'pitch_angle', 'outputs', config.body_state.pitch, '车身俯仰角', 'Body Pitch Angle', 'rad'};
    {'pitch_v', 'outputs', config.body_state.vpitch, '车身俯仰角速度', 'Body Pitch Velocity', 'rad/s'};
    {'front_susp_def', 'states', config.states.front_susp_def, '前悬架动行程', 'Front Suspension Deflection', 'm'};
    {'rear_susp_def', 'states', config.states.rear_susp_def, '后悬架动行程', 'Rear Suspension Deflection', 'm'};
    {'front_tire_def', 'states', config.states.front_tire_def, '前轮胎动变形', 'Front Tire Deflection', 'm'};
    {'rear_tire_def', 'states', config.states.rear_tire_def, '后轮胎动变形', 'Rear Tire Deflection', 'm'};
};

end

%% 四分之一车模型配置
function config = set_quarter_car_config(config)

% 数据字段映射配置
config.data_fields.time = 'tout';
config.data_fields.outputs = 'y_bus';      % 系统输出
config.data_fields.road_input = 'xr';      % 路面输入
config.data_fields.states = 'real_x_bus';  % 真实状态

% 输出信号索引映射 (基于y_bus，四分之一车模型)
config.signals.sprung_acc = 1;            % 簧载质量加速度
config.signals.rel_vel = 2;               % 悬架相对速度
config.signals.unsprung_acc = 3;          % 非簧载质量加速度
config.signals.tire_force = 4;            % 轮胎力（如果有）

% 状态信号索引映射
config.states.tire_def = 1;               % 轮胎变形
config.states.susp_def = 2;               % 悬架变形

% 路面输入索引映射
config.road.input = 1;                    % 路面输入

% 分析信号配置
config.analysis_signals = {
    % {信号名称, 数据来源, 索引, 中文标签, 英文标签, 单位}
    {'sprung_acc', 'outputs', config.signals.sprung_acc, '簧载质量加速度', 'Sprung Mass Acceleration', 'm/s²'};
    {'unsprung_acc', 'outputs', config.signals.unsprung_acc, '非簧载质量加速度', 'Unsprung Mass Acceleration', 'm/s²'};
    {'susp_def', 'states', config.states.susp_def, '悬架动行程', 'Suspension Deflection', 'm'};
    {'tire_def', 'states', config.states.tire_def, '轮胎动变形', 'Tire Deflection', 'm'};
};

end

%% 生成带时间戳的结果文件夹路径
function output_folder = get_timestamped_results_folder()
    % 生成格式: results/YYYY-MM-DD_HH-MM-SS
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    base_folder = 'results';
    output_folder = fullfile(base_folder, timestamp);
    
    % 创建文件夹（如果不存在）
    if ~exist(output_folder, 'dir')
        mkdir(output_folder);
        fprintf('创建结果文件夹: %s\n', output_folder);
    end
end