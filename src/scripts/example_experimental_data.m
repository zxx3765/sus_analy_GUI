%% 实验数据分析示例
% 演示如何使用GUI分析实验数据
%
% 使用方法:
% 1. 加载实验数据到工作空间
% 2. 启动GUI: launch_gui 或 suspension_analysis_gui
% 3. 使用"工作空间导入"或"文件导入"按钮导入数据
% 4. GUI会自动检测并转换实验数据格式
% 5. 使用分析功能进行分析

%% 示例: 加载并转换实验数据
% 假设你的实验数据文件路径
% exp_data_file = 'HIL_data\HIL_Data_1018\Sweep.mat';

% 加载数据
% DATA = load(exp_data_file);

% 提取单个实验数据集
% exp_passive = DATA.Sweep_00A;
% exp_shadd = DATA.Sweep_SHADD;

% 数据会自动在GUI中转换为兼容格式
% 转换后的数据包含以下字段:
%   - tout: 时间向量
%   - as: 车身加速度 (Y3)
%   - x_def: 悬架行程 (Y13)
%   - xr: 路面输入 (Y14)
%   - xu_pos: 轮胎位置 (Y16)
%   - x_tire: 轮胎变形 (计算得出)
%   - Y1-YN: 所有原始信号

%% 手动转换示例 (可选)
% 如果需要在GUI外手动转换:
% converted_data = convert_experimental_data(exp_passive, 'Passive');

fprintf('实验数据分析功能已集成到GUI中\n');
fprintf('请使用 launch_gui 或 suspension_analysis_gui 启动界面\n');
