function converted_struct = convert_experimental_data(exp_data, var_name)
%CONVERT_EXPERIMENTAL_DATA 将实验数据格式转换为仿真数据格式
%
% 输入:
%   exp_data - 实验数据结构 (包含.X和.Y字段)
%   var_name - 变量名称 (用于日志)
%
% 输出:
%   converted_struct - 转换后的结构体 (与仿真数据格式兼容)
%                      包含tout和各信号字段

    converted_struct = struct();

    try
        % 提取时间向量
        if isfield(exp_data, 'X') && ~isempty(exp_data.X)
            time_data = exp_data.X(1).Data;
            % 确保是列向量
            converted_struct.tout = time_data(:);
        else
            error('未找到时间数据 (X字段)');
        end

        % 提取信号数据
        if isfield(exp_data, 'Y') && ~isempty(exp_data.Y)
            num_signals = length(exp_data.Y);

            % 获取数据长度
            data_length = length(converted_struct.tout);

            % 创建quarter车型所需的数据结构
            % state_dot: [N×4] 矩阵，第2列是簧载加速度，第4列是非簧载加速度
            converted_struct.state_dot = zeros(data_length, 4);
            if num_signals >= 3
                converted_struct.state_dot(:, 2) = exp_data.Y(3).Data(:);  % 簧载加速度
            end

            % state: [N×6] 矩阵，第5列是轮胎变形
            converted_struct.state = zeros(data_length, 6);

            % xr: 路面输入
            if num_signals >= 14
                converted_struct.xr = exp_data.Y(14).Data(:);
            end

            % x_def: 悬架行程
            if num_signals >= 13
                converted_struct.x_def = exp_data.Y(13).Data(:);
            end

            % 计算轮胎变形并放入state第5列
            if num_signals >= 16 && num_signals >= 14
                xu_pos = exp_data.Y(16).Data(:);
                tire_def = xu_pos - converted_struct.xr;
                converted_struct.state(:, 5) = tire_def;
            end

            % 保留所有原始信号供参考
            for i = 1:num_signals
                generic_name = sprintf('Y%d', i);
                converted_struct.(generic_name) = exp_data.Y(i).Data(:);
            end
        else
            error('未找到信号数据 (Y字段)');
        end

    catch ME
        warning('转换实验数据失败: %s', ME.message);
        converted_struct = [];
    end
end
