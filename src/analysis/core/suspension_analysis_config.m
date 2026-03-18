function config = suspension_analysis_config(model_type)
%% 悬架分析通用配置文件
% 输入参数: 
%   model_type: 'half' (半车模型) 或 'quarter' (四分之一车模型) 或 'full' (整车模型)
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
config.analysis.peak_comparison = false;     % 峰值对比分析（柱形图），默认关闭（不区分正负）

%% 绘图配置
config.plot.line_width = 1.5;
config.plot.font_size = 12;
config.plot.figure_size = [800, 600];
config.plot.reference_lines = [];  % 参考线频率，如 [11, 25]

%% 图例控制配置
config.plot.legend_preset = 'default';  % 图例预设样式: 'default', 'compact', 'presentation', 'paper', 'colorful', 'minimal', 'hidden'
config.plot.legend_position = 'auto';   % 图例位置: 'auto' 或具体位置如 'northeast', 'eastoutside' 等
config.plot.legend_show = true;         % 是否显示图例
config.plot.legend_font_size = [];      % 图例字体大小，空则使用默认
config.plot.custom_labels = {};         % 自定义标签映射，格式: {'原标签1', '新标签1'; '原标签2', '新标签2'}

%% 语言配置 ('cn' 或 'en')
config.language = 'cn';

%% 根据模型类型设置具体配置
switch lower(model_type)
    case 'half'
        config = set_half_car_config(config);
    case 'quarter'
        config = set_quarter_car_config(config);
    case 'full'
        config = set_full_car_config(config);
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
config.data_fields.body_state_bus = 'body_state_bus';  %车身状态
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
    {'body_x', 'body_state_bus', config.body_state.xs, '车身质心位移', 'Body Center Displacement', 'm'};
    {'body_v', 'body_state_bus', config.body_state.vs, '车身质心速度', 'Body Center Velocity', 'm/s'};
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
config.data_fields.time = 'tout';           % 时间数据
config.data_fields.state_dot = 'state_dot'; % 状态导数 [5001×4]
config.data_fields.state = 'state';         % 状态数据 [5001×6]
config.data_fields.road_input = 'xr';       % 路面输入 [5001×1]
config.data_fields.reward = 'reward';       % 奖励数据 [5001×1]
config.data_fields.road_derivative = 'd_xr'; % 路面输入导数 [5001×1]
config.data_fields.velocity_def = 'v_def';  % 速度缺陷 [5001×1]
config.data_fields.x_def = 'x_def';  

% 状态导数信号索引映射 (基于state_dot [5001×4])
config.signals.signal_1 = 1;                % 第1个状态导数信号
config.signals.sprung_acc = 2;              % 第2个状态导数信号（簧载质量加速度）
config.signals.signal_3 = 3;                % 第3个状态导数信号
config.signals.unsprung_acc = 4;            % 第4个状态导数信号（非簧载质量加速度）

% 状态信号索引映射 (基于state [5001×6])
config.states.state_1 = 1;                  % 第1个状态信号
config.states.state_2 = 2;                  % 第2个状态信号
config.states.state_3 = 3;                  % 第3个状态信号
config.states.state_4 = 4;                  % 第4个状态信号

config.states.tire_def = 5;                 % 第6个状态信号（轮胎变形）

% 其他单一信号索引映射
config.road.input = 1;                      % 路面输入索引
config.reward.total = 1;                    % 总奖励索引
config.road_derivative.input = 1;           % 路面输入导数索引
config.velocity_def.value = 1;              % 速度缺陷索引
config.states.susp_def = 1;                 % 悬架变形
% 分析信号配置 - 根据实际数据结构
config.analysis_signals = {
    % {信号名称, 数据来源, 索引, 中文标签, 英文标签, 单位}
    
    % 基于状态导数的信号 (state_dot)
    {'sprung_acc', 'state_dot', config.signals.sprung_acc, '簧载质量加速度', 'Sprung Mass Acceleration', 'm/s²'};
    {'unsprung_acc', 'state_dot', config.signals.unsprung_acc, '非簧载质量加速度', 'Unsprung Mass Acceleration', 'm/s²'};
    
    % 基于状态的信号 (state)
    {'susp_def', 'x_def', config.states.susp_def, '悬架动行程', 'Suspension Deflection', 'm'};
    {'tire_def', 'state', config.states.tire_def, '轮胎动变形', 'Tire Deflection', 'm'};
    
    % 单一信号
    {'reward', 'reward', config.reward.total, '奖励信号', 'Reward Signal', ''};
    {'road_input', 'road_input', config.road.input, '路面输入', 'Road Input', 'm'};
    {'velocity_def', 'velocity_def', config.velocity_def.value, '速度缺陷', 'Velocity Defect', 'm/s'};
};

end

%% 整车模型配置 (7-DOF)
function config = set_full_car_config(config)

% 数据字段映射配置
config.data_fields.time = 'tout';
config.data_fields.outputs = 'y_bus';      % 系统输出（保留）
config.data_fields.road_input = 'xr_bus';  % 路面输入总线（4列）
config.data_fields.states = 'real_x_bus';  % 真实状态
config.data_fields.body_bus = 'body_bus';  % 车身状态总线（9列）
config.data_fields.wheel_bus = 'wheel_bus'; % 轮端状态总线（12列）
config.data_fields.corner_bus = 'corner_bus'; % 簧载角点状态总线（8列）
config.data_fields.body_state_bus = 'body_state_bus';  % 保留兼容
config.data_fields.unsprung_state_bus = 'unsprung_state';  % 保留兼容

% 车身状态总线索引 (基于body_bus: XS, VS, as, theta, vtheta, atheta, phi, vphi, aphi)
config.body_state.xs = 1;                  % XS - 车身垂向位移
config.body_state.vs = 2;                  % VS - 车身垂向速度
config.body_state.as = 3;                  % as - 车身垂向加速度
config.body_state.theta = 4;               % theta - 俯仰角
config.body_state.vtheta = 5;              % vtheta - 俯仰角速度
config.body_state.atheta = 6;              % atheta - 俯仰角加速度
config.body_state.phi = 7;                 % phi - 侧倾角
config.body_state.vphi = 8;               % vphi - 侧倾角速度
config.body_state.aphi = 9;               % aphi - 侧倾角加速度

% 轮端状态总线索引 (基于wheel_bus: xu_FL, vu_FL, au_FL, xu_FR, vu_FR, au_FR,
%                                   xu_RL, vu_RL, au_RL, xu_RR, vu_RR, au_RR)
config.wheel.xu_fl = 1;                    % xu_FL - 左前非簧载位移
config.wheel.vu_fl = 2;                    % vu_FL - 左前非簧载速度
config.wheel.au_fl = 3;                    % au_FL - 左前非簧载加速度
config.wheel.xu_fr = 4;                    % xu_FR - 右前非簧载位移
config.wheel.vu_fr = 5;                    % vu_FR - 右前非簧载速度
config.wheel.au_fr = 6;                    % au_FR - 右前非簧载加速度
config.wheel.xu_rl = 7;                    % xu_RL - 左后非簧载位移
config.wheel.vu_rl = 8;                    % vu_RL - 左后非簧载速度
config.wheel.au_rl = 9;                    % au_RL - 左后非簧载加速度
config.wheel.xu_rr = 10;                   % xu_RR - 右后非簧载位移
config.wheel.vu_rr = 11;                   % vu_RR - 右后非簧载速度
config.wheel.au_rr = 12;                   % au_RR - 右后非簧载加速度

% 簧载角点状态总线索引 (基于corner_bus: xb_FL, xb_FR, xb_RL, xb_RR,
%                                       vb_FL, vb_FR, vb_RL, vb_RR)
config.corner.xb_fl = 1;                   % xb_FL - 左前簧载位移
config.corner.xb_fr = 2;                   % xb_FR - 右前簧载位移
config.corner.xb_rl = 3;                   % xb_RL - 左后簧载位移
config.corner.xb_rr = 4;                   % xb_RR - 右后簧载位移
config.corner.vb_fl = 5;                   % vb_FL - 左前簧载速度
config.corner.vb_fr = 6;                   % vb_FR - 右前簧载速度
config.corner.vb_rl = 7;                   % vb_RL - 左后簧载速度
config.corner.vb_rr = 8;                   % vb_RR - 右后簧载速度

% 状态信号索引映射 (基于real_x_bus) — 占位符索引
config.states.lf_tire_def = 1;             % 左前轮胎变形
config.states.rf_tire_def = 2;             % 右前轮胎变形
config.states.lr_tire_def = 3;             % 左后轮胎变形
config.states.rr_tire_def = 4;             % 右后轮胎变形
config.states.lf_susp_def = 5;             % 左前悬架变形
config.states.rf_susp_def = 6;             % 右前悬架变形
config.states.lr_susp_def = 7;             % 左后悬架变形
config.states.rr_susp_def = 8;             % 右后悬架变形

% 路面输入索引映射 (基于xr_bus: xr_FL, xr_RL, xr_FR, xr_RR)
config.road.lf_input = 1;                  % xr_FL - 左前轮路面输入
config.road.lr_input = 2;                  % xr_RL - 左后轮路面输入
config.road.rf_input = 3;                  % xr_FR - 右前轮路面输入
config.road.rr_input = 4;                  % xr_RR - 右后轮路面输入

% 分析信号配置 — 21个信号
config.analysis_signals = {
    % {信号名称, 数据来源, 索引, 中文标签, 英文标签, 单位}

    % 车身（3个）— 来自body_bus
    {'body_acc', 'body_bus', config.body_state.as, '车身质心垂向加速度', 'Body Vertical Acceleration', 'm/s²'};
    {'body_x', 'body_bus', config.body_state.xs, '车身质心垂向位移', 'Body Vertical Displacement', 'm'};
    {'body_v', 'body_bus', config.body_state.vs, '车身质心垂向速度', 'Body Vertical Velocity', 'm/s'};

    % 俯仰（3个）— 来自body_bus
    {'pitch_acc', 'body_bus', config.body_state.atheta, '俯仰角加速度', 'Pitch Angular Acceleration', 'rad/s²'};
    {'pitch_angle', 'body_bus', config.body_state.theta, '俯仰角', 'Pitch Angle', 'rad'};
    {'pitch_v', 'body_bus', config.body_state.vtheta, '俯仰角速度', 'Pitch Angular Velocity', 'rad/s'};

    % 侧倾（3个）— 来自body_bus
    {'roll_acc', 'body_bus', config.body_state.aphi, '侧倾角加速度', 'Roll Angular Acceleration', 'rad/s²'};
    {'roll_angle', 'body_bus', config.body_state.phi, '侧倾角', 'Roll Angle', 'rad'};
    {'roll_v', 'body_bus', config.body_state.vphi, '侧倾角速度', 'Roll Angular Velocity', 'rad/s'};

    % 非簧载质量加速度（4个）— 来自wheel_bus
    {'lf_unsprung_acc', 'wheel_bus', config.wheel.au_fl, '左前非簧载质量加速度', 'LF Unsprung Mass Acceleration', 'm/s²'};
    {'rf_unsprung_acc', 'wheel_bus', config.wheel.au_fr, '右前非簧载质量加速度', 'RF Unsprung Mass Acceleration', 'm/s²'};
    {'lr_unsprung_acc', 'wheel_bus', config.wheel.au_rl, '左后非簧载质量加速度', 'LR Unsprung Mass Acceleration', 'm/s²'};
    {'rr_unsprung_acc', 'wheel_bus', config.wheel.au_rr, '右后非簧载质量加速度', 'RR Unsprung Mass Acceleration', 'm/s²'};

    % 悬架动行程（4个）— 来自real_x_bus
    {'lf_susp_def', 'states', config.states.lf_susp_def, '左前悬架动行程', 'LF Suspension Deflection', 'm'};
    {'rf_susp_def', 'states', config.states.rf_susp_def, '右前悬架动行程', 'RF Suspension Deflection', 'm'};
    {'lr_susp_def', 'states', config.states.lr_susp_def, '左后悬架动行程', 'LR Suspension Deflection', 'm'};
    {'rr_susp_def', 'states', config.states.rr_susp_def, '右后悬架动行程', 'RR Suspension Deflection', 'm'};

    % 轮胎动变形（4个）— 来自real_x_bus
    {'lf_tire_def', 'states', config.states.lf_tire_def, '左前轮胎动变形', 'LF Tire Deflection', 'm'};
    {'rf_tire_def', 'states', config.states.rf_tire_def, '右前轮胎动变形', 'RF Tire Deflection', 'm'};
    {'lr_tire_def', 'states', config.states.lr_tire_def, '左后轮胎动变形', 'LR Tire Deflection', 'm'};
    {'rr_tire_def', 'states', config.states.rr_tire_def, '右后轮胎动变形', 'RR Tire Deflection', 'm'};
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