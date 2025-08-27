%% convert_simulink_output.m - 转换Simulink.SimulationOutput对象
% 将新版Simulink的SimulationOutput对象转换为GUI兼容的结构体格式

function convert_simulink_output(input_file, output_file)
    if nargin < 1
        [filename, pathname] = uigetfile('*.mat', '选择包含SimulationOutput的文件');
        if isequal(filename, 0)
            return;
        end
        input_file = fullfile(pathname, filename);
    end
    
    if nargin < 2
        [~, name, ~] = fileparts(input_file);
        output_file = [name '_converted.mat'];
    end
    
    fprintf('=== Simulink输出转换工具 ===\n');
    fprintf('输入文件: %s\n', input_file);
    fprintf('输出文件: %s\n\n', output_file);
    
    try
        % 加载原始数据
        loaded_data = load(input_file);
        field_names = fieldnames(loaded_data);
        
        fprintf('找到 %d 个变量: %s\n\n', length(field_names), strjoin(field_names, ', '));
        
        converted_data = struct();
        conversion_count = 0;
        
        % 处理每个变量
        for i = 1:length(field_names)
            var_name = field_names{i};
            var_data = loaded_data.(var_name);
            
            fprintf('处理变量: %s\n', var_name);
            
            % 检查是否为SimulationOutput对象
            if isa(var_data, 'Simulink.SimulationOutput')
                fprintf('  类型: Simulink.SimulationOutput\n');
                
                try
                    % 转换为结构体
                    converted_struct = convertToStruct(var_data);
                    
                    if ~isempty(converted_struct)
                        converted_data.(var_name) = converted_struct;
                        conversion_count = conversion_count + 1;
                        fprintf('  ✓ 转换成功\n');
                        
                        % 显示转换后的信息
                        if isfield(converted_struct, 'tout')
                            time_info = sprintf('时间: %.3f-%.3f s (%d 点)', ...
                                converted_struct.tout(1), converted_struct.tout(end), length(converted_struct.tout));
                            fprintf('    %s\n', time_info);
                        end
                        
                        if isfield(converted_struct, 'y_bus')
                            y_size = size(converted_struct.y_bus);
                            fprintf('    输出通道: %d, 数据点: %d\n', y_size(2), y_size(1));
                        end
                        
                        if isfield(converted_struct, 'xr')
                            xr_size = size(converted_struct.xr);
                            fprintf('    输入通道: %d, 数据点: %d\n', xr_size(2), xr_size(1));
                        end
                    else
                        fprintf('  ✗ 转换失败: 无法提取有效数据\n');
                    end
                    
                catch ME
                    fprintf('  ✗ 转换失败: %s\n', ME.message);
                end
                
            else
                fprintf('  类型: %s - 跳过（不需要转换）\n', class(var_data));
                % 如果已经是结构体格式，直接复制
                if isstruct(var_data)
                    converted_data.(var_name) = var_data;
                end
            end
            
            fprintf('\n');
        end
        
        % 保存转换结果
        if conversion_count > 0
            save(output_file, '-struct', 'converted_data');
            fprintf('=== 转换完成 ===\n');
            fprintf('✓ 成功转换 %d 个变量\n', conversion_count);
            fprintf('转换后的文件: %s\n', output_file);
            fprintf('\n现在可以在GUI中导入: %s\n', output_file);
        else
            fprintf('=== 转换失败 ===\n');
            fprintf('✗ 没有找到可转换的SimulationOutput对象\n');
        end
        
    catch ME
        fprintf('✗ 转换过程出错: %s\n', ME.message);
    end
end

%% 将SimulationOutput转换为结构体
function result_struct = convertToStruct(sim_output)
    result_struct = struct();
    
    try
        % 获取时间向量
        if isprop(sim_output, 'tout') || isfield(sim_output, 'tout')
            result_struct.tout = sim_output.tout;
        elseif isprop(sim_output, 'time') || isfield(sim_output, 'time')
            result_struct.tout = sim_output.time;
        else
            % 尝试从其他信号中获取时间信息
            signal_names = fieldnames(sim_output);
            for i = 1:length(signal_names)
                signal = sim_output.(signal_names{i});
                if isobject(signal) && isprop(signal, 'Time')
                    result_struct.tout = signal.Time;
                    break;
                end
            end
        end
        
        % 如果还是没有时间向量，跳过此变量
        if ~isfield(result_struct, 'tout')
            fprintf('    警告: 未找到时间向量\n');
            result_struct = [];
            return;
        end
        
        % 获取所有信号
        signal_names = fieldnames(sim_output);
        fprintf('    找到 %d 个信号: %s\n', length(signal_names), strjoin(signal_names, ', '));
        
        % 处理常见的信号名
        for i = 1:length(signal_names)
            signal_name = signal_names{i};
            
            % 跳过时间字段
            if strcmpi(signal_name, 'tout') || strcmpi(signal_name, 'time')
                continue;
            end
            
            try
                signal = sim_output.(signal_name);
                
                % 处理不同类型的信号对象
                if isobject(signal)
                    % Simulink.SimulationData.Dataset 或类似对象
                    if isprop(signal, 'Data') || isfield(signal, 'Data')
                        signal_data = signal.Data;
                    elseif isprop(signal, 'Values') || isfield(signal, 'Values')
                        signal_data = signal.Values;
                    else
                        % 尝试直接转换
                        signal_data = double(signal);
                    end
                else
                    signal_data = signal;
                end
                
                % 存储信号数据
                result_struct.(signal_name) = signal_data;
                
            catch ME2
                fprintf('    警告: 无法处理信号 %s: %s\n', signal_name, ME2.message);
            end
        end
        
    catch ME
        fprintf('    错误: %s\n', ME.message);
        result_struct = [];
    end
end