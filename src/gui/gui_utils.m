function varargout = gui_utils(varargin)
%% GUI工具函数模块
% 提供GUI通用的工具函数
%
% 功能:
% - 添加日志
% - 数据验证
% - 文件处理
% - 用户界面更新
%
% 用法:
%   addLog(handles, message)           - 添加日志条目
%   validateSimData(data)             - 验证仿真数据
%   convertSimulinkOutput(sim_output) - 转换Simulink输出
%
% 作者: Claude Code Assistant
% 日期: 2024

if nargin < 1
    error('gui_utils: 至少需要一个参数');
end

func_name = varargin{1};

switch func_name
    case 'addLog'
        if nargin >= 3
            addLog(varargin{2}, varargin{3});
        end
    case 'updateSignalList'
        if nargin >= 3
            updateSignalListFromUtils(varargin{2}, varargin{3});
        end
    case 'refreshResultsList'
        if nargin >= 2
            refreshResultsList(varargin{2});
        end
    case 'validateSimData'
        if nargin >= 2
            varargout{1} = validateSimData(varargin{2});
        end
    case 'convertSimulinkOutput'
        if nargin >= 2
            varargout{1} = convertSimulinkOutput(varargin{2});
        end
    otherwise
        warning('gui_utils: 未知函数 %s', func_name);
end

end

%% 添加日志
function addLog(handles, message)
%ADDLOG 向GUI日志区域添加带时间戳的日志条目
%
% 输入:
%   handles - GUI句柄结构体
%   message - 日志消息字符串
%
% 功能:
%   - 自动添加时间戳
%   - 限制日志长度防止内存溢出
%   - 自动滚动到最新条目
%   - 错误处理和备用输出

    try
        % 验证handles结构体和logText控件
        if ~isstruct(handles) || ~isfield(handles, 'logText')
            fprintf('[GUI日志] %s\n', message); % 如果GUI不可用，输出到命令窗口
            return;
        end
        
        % 验证logText控件是否有效
        if ~ishandle(handles.logText)
            fprintf('[GUI日志] %s\n', message);
            return;
        end
        
        current_log = get(handles.logText, 'String');
        timestamp = datestr(now, 'HH:MM:SS');
        new_entry = sprintf('[%s] %s', timestamp, message);
        
        if ischar(current_log)
            if isempty(current_log)
                new_log = {new_entry};
            else
                new_log = {current_log; new_entry};
            end
        else
            new_log = [current_log; {new_entry}];
        end
        
        % 限制日志长度
        if length(new_log) > 100
            new_log = new_log(end-99:end);
        end
        
        set(handles.logText, 'String', new_log);
        
        % 滚动到底部
        set(handles.logText, 'Value', length(new_log));
        drawnow;
        
    catch ME
        % 如果日志功能失败，至少输出到命令窗口
        fprintf('[GUI日志失败] %s\n', message);
        fprintf('[错误] %s\n', ME.message);
    end
end

%% 验证仿真数据
function isValid = validateSimData(data)
%VALIDATESIMDATA 验证数据是否为有效的仿真数据结构
%
% 输入:
%   data - 待验证的数据结构
%
% 输出:
%   isValid - 逻辑值，true表示有效

    isValid = false;
    
    try
        % 检查是否为结构体
        if ~isstruct(data)
            return;
        end
        
        % 检查必需的时间字段
        has_tout = isfield(data, 'tout');
        has_time = isfield(data, 'time') || isfield(data, 't');
        
        if ~(has_tout || has_time)
            return;
        end
        
        % 获取时间字段
        if has_tout
            time_data = data.tout;
        elseif isfield(data, 'time')
            time_data = data.time;
        else
            time_data = data.t;
        end
        
        % 验证时间数据
        if ~isnumeric(time_data) || length(time_data) <= 1
            return;
        end
        
        % 检查时间数据是否单调递增
        if ~all(diff(time_data) > 0)
            return;
        end
        
        isValid = true;
        
    catch
        isValid = false;
    end
end

%% 转换Simulink输出对象为结构体
function result_struct = convertSimulinkOutput(sim_output)
%CONVERTSIMULINKEOUTPUT 将Simulink.SimulationOutput对象转换为标准结构体
%
% 输入:
%   sim_output - Simulink仿真输出对象
%
% 输出:
%   result_struct - 转换后的结构体，失败时返回空数组

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
            result_struct = [];
            return;
        end
        
        % 获取所有信号
        signal_names = fieldnames(sim_output);
        
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
                
            catch
                % 忽略无法处理的信号
                continue;
            end
        end
        
    catch
        result_struct = [];
    end
end

%% 生成唯一的输出文件夹名
function folder_name = generateUniqueFolder(base_name) %#ok<DEFNU>
%GENERATEUNIQUEFOLDER 生成唯一的文件夹名称
%
% 输入:
%   base_name - 基础文件夹名
%
% 输出:
%   folder_name - 唯一的文件夹名

    if nargin < 1
        base_name = 'results';
    end
    
    % 添加时间戳
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    folder_name = sprintf('%s_%s', base_name, timestamp);
    
    % 如果仍然存在，添加计数器
    counter = 1;
    original_name = folder_name;
    while exist(folder_name, 'dir')
        folder_name = sprintf('%s_%d', original_name, counter);
        counter = counter + 1;
    end
end

%% 安全的文件名生成
function safe_name = makeSafeFilename(filename) %#ok<DEFNU>
%MAKESAFEFILENAME 生成安全的文件名，移除无效字符
%
% 输入:
%   filename - 原始文件名
%
% 输出:
%   safe_name - 安全的文件名

    % 移除或替换无效字符
    invalid_chars = '<>:"/\|?*';
    safe_name = filename;
    
    for i = 1:length(invalid_chars)
        safe_name = strrep(safe_name, invalid_chars(i), '_');
    end
    
    % 移除首尾空格
    safe_name = strtrim(safe_name);
    
    % 确保不为空
    if isempty(safe_name)
        safe_name = 'untitled';
    end
    
    % 限制长度
    if length(safe_name) > 100
        safe_name = safe_name(1:100);
    end
end

%% 检查必需的工具箱
function [available, missing] = checkRequiredToolboxes() %#ok<DEFNU>
%CHECKREQUIREDTOOLBOXES 检查必需的MATLAB工具箱是否可用
%
% 输出:
%   available - 可用工具箱列表
%   missing - 缺失工具箱列表

    required_toolboxes = {
        'Control System Toolbox', 'control';
        'Signal Processing Toolbox', 'signal';
        'Simulink', 'simulink'
    };
    
    available = {};
    missing = {};
    
    for i = 1:size(required_toolboxes, 1)
        toolbox_name = required_toolboxes{i, 1};
        toolbox_id = required_toolboxes{i, 2};
        
        try
            % 检查工具箱是否存在
            v = ver(toolbox_id);
            if ~isempty(v)
                available{end+1} = toolbox_name; %#ok<AGROW>
            else
                missing{end+1} = toolbox_name; %#ok<AGROW>
            end
        catch
            missing{end+1} = toolbox_name; %#ok<AGROW>
        end
    end
end

%% 格式化文件大小
function size_str = formatFileSize(bytes) %#ok<DEFNU>
%FORMATFILESIZE 将字节数格式化为可读的文件大小字符串
%
% 输入:
%   bytes - 文件大小（字节）
%
% 输出:
%   size_str - 格式化的文件大小字符串

    if bytes < 1024
        size_str = sprintf('%d B', bytes);
    elseif bytes < 1024^2
        size_str = sprintf('%.1f KB', bytes/1024);
    elseif bytes < 1024^3
        size_str = sprintf('%.1f MB', bytes/1024^2);
    else
        size_str = sprintf('%.1f GB', bytes/1024^3);
    end
end

%% 获取系统信息
function info = getSystemInfo() %#ok<DEFNU>
%GETSYSTEMINFO 获取系统和MATLAB环境信息
%
% 输出:
%   info - 包含系统信息的结构体

    info = struct();
    
    try
        % MATLAB版本信息
        info.matlab_version = version;
        info.matlab_release = version('-release');
        
        % 系统信息
        info.computer = computer;
        info.architecture = computer('arch');
        
        % 内存信息
        try
            mem_info = memory;
            info.max_possible_array = mem_info.MaxPossibleArrayBytes;
            info.memory_available = mem_info.MemAvailableAllArrays;
        catch
            info.max_possible_array = NaN;
            info.memory_available = NaN;
        end
        
        % Java信息
        try
            info.java_version = char(java.lang.System.getProperty('java.version'));
        catch
            info.java_version = 'Unknown';
        end
        
    catch ME
        warning('%s', ['获取系统信息失败: ' ME.message]);
    end
end

%% 刷新结果列表
function refreshResultsList(handles)
%REFRESHRESULTSLIST 刷新GUI中的结果文件列表
%
% 输入:
%   handles - GUI句柄结构体
%
% 功能:
%   - 扫描结果文件夹中的文件
%   - 按类型分类文件
%   - 更新结果列表显示

    if ~isfield(handles, 'results_folder') || isempty(handles.results_folder) || ~exist(handles.results_folder, 'dir')
        if isfield(handles, 'resultsFileList')
            set(handles.resultsFileList, 'String', {'(无结果文件)'});
        end
        return;
    end
    
    % 获取结果文件
    files = dir(fullfile(handles.results_folder, '*.*'));
    files = files(~[files.isdir]); % 只要文件
    
    if isempty(files)
        if isfield(handles, 'resultsFileList')
            set(handles.resultsFileList, 'String', {'(文件夹为空)'});
        end
        return;
    end
    
    % 按类型排序文件
    image_files = {};
    data_files = {};
    other_files = {};
    
    for i = 1:length(files)
        [~, ~, ext] = fileparts(files(i).name);
        switch lower(ext)
            case {'.png', '.jpg', '.jpeg', '.eps', '.pdf'}
                image_files{end+1} = files(i).name;
            case {'.mat', '.txt'}
                data_files{end+1} = files(i).name;
            otherwise
                other_files{end+1} = files(i).name;
        end
    end
    
    % 组合文件列表
    file_list = {};
    if ~isempty(image_files)
        file_list = [file_list; {'--- 图像文件 ---'}; sort(image_files)'];
    end
    if ~isempty(data_files)
        file_list = [file_list; {'--- 数据文件 ---'}; sort(data_files)'];
    end
    if ~isempty(other_files)
        file_list = [file_list; {'--- 其他文件 ---'}; sort(other_files)'];
    end
    
    if isfield(handles, 'resultsFileList')
        set(handles.resultsFileList, 'String', file_list);
    end
    
    gui_utils('addLog', handles, sprintf('结果列表已刷新，找到 %d 个文件', length(files)));
end

%% 从工具函数更新信号列表
function updateSignalListFromUtils(model_type, handles)
%UPDATESIGNALLISTFROMUTILS 通过工具函数更新信号列表
%
% 输入:
%   model_type - 模型类型 ('half' 或 'quarter')
%   handles - GUI句柄结构体
%
% 功能:
%   - 根据模型类型获取对应的信号列表
%   - 更新GUI中的信号选择列表
%   - 添加日志记录

    if nargin < 2
        warning('updateSignalListFromUtils: 参数不足');
        return;
    end
    
    % 检查handles是否有效
    if ~isfield(handles, 'signalList')
        return;
    end
    
    try
        % 获取handles（如果需要从UserData获取）
        if isfield(handles, 'fig')
            handles = get(handles.fig, 'UserData');
        end
        
    % 始终允许选择信号（即使未导入数据，也先展示可选项）
    set(handles.signalList, 'Enable', 'on');
        
        % 根据模型类型获取信号列表
        preset_signals = getSignalListByModelType(model_type);
        
        % 更新信号列表
        set(handles.signalList, 'String', preset_signals);
        set(handles.signalList, 'Value', []); % 清除当前选择
        
        % 添加日志
        gui_utils('addLog', handles, sprintf('已更新%s模型信号列表，共 %d 个信号', ...
            getModelTypeName(model_type), length(preset_signals)));
        
        % 保存handles（如果有fig字段）
        if isfield(handles, 'fig')
            set(handles.fig, 'UserData', handles);
        end
        
    catch ME
        warning('%s', ['更新信号列表失败: ' ME.message]);
    end
end

%% 根据模型类型获取信号列表（工具函数版本）
function signals = getSignalListByModelType(model_type)
    try
        % 从配置文件获取信号定义
        config = suspension_analysis_config(model_type);
        
        % 提取中文标签
        signals = {};
        for i = 1:length(config.analysis_signals)
            signal_def = config.analysis_signals{i};
            if length(signal_def) >= 4
                signals{end+1} = signal_def{4}; % 中文标签
            end
        end
        
        if isempty(signals)
            % 如果配置文件中没有信号，使用默认信号
            signals = getDefaultSignals(model_type);
        end
        
    catch ME
        warning('%s', ['获取信号配置失败: ' ME.message]);
        % 使用默认信号列表
        signals = getDefaultSignals(model_type);
    end
end

%% 获取默认信号列表（工具函数版本）
function signals = getDefaultSignals(model_type)
    switch lower(model_type)
        case 'half'
            signals = {
                '车身质心位移',
                '车身质心速度',
                '车身质心加速度',
                '车身俯仰角',
                '车身俯仰角速度',
                '车身俯仰角加速度',
                '前簧载质量加速度',
                '后簧载质量加速度',
                '前悬架动行程',
                '后悬架动行程',
                '前轮胎动变形',
                '后轮胎动变形'
            };
        case 'quarter'
            signals = {
                '簧载质量加速度',
                '非簧载质量加速度',
                '悬架动行程',
                '轮胎动变形'
            };
        otherwise
            signals = {'(无可用信号)'};
    end
end

%% 获取模型类型的中文名称（工具函数版本）
function name = getModelTypeName(model_type)
    switch lower(model_type)
        case 'half'
            name = '半车';
        case 'quarter'
            name = '四分之一车';
        otherwise
            name = '未知';
    end
end