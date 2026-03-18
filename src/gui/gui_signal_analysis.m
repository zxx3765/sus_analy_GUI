function handles = gui_signal_analysis(parent, handles)
%% 信号选择和分析控制模块
% 负责信号选择和分析执行的控制
%
% 功能:
% - 信号选择 (多选)
% - 快速选择操作 (全选/取消)
% - 分析执行控制
% - 分析状态显示
% - 进度条显示
%
% 输入:
%   parent - 父容器对象
%   handles - GUI句柄结构体
%
% 输出:  
%   handles - 更新后的句柄结构体

    % 根据模型类型获取信号列表
    if isfield(handles, 'config') && isfield(handles.config, 'model_type')
        model_type = handles.config.model_type;
    else
        model_type = 'half'; % 默认
    end
    preset_signals = getSignalListByModelType(model_type);
    
    % 信号选择面板 - 重新设计布局，包含分析控制
    signalPanel = uipanel('Parent', parent, ...
                         'Title', '⚙️ 信号选择 & 分析控制', ...
                         'Units', 'normalized', ...
                         'Position', [0.02, 0.02, 0.96, 0.96], ...
                         'FontSize', 10, ...
                         'FontWeight', 'bold', ...
                         'BackgroundColor', [0.98, 0.99, 0.98], ...
                         'ForegroundColor', [0.25, 0.45, 0.80]);
    
    % === 信号选择区域 ===
    % 添加说明文字
    uicontrol('Parent', signalPanel, ...
              'Style', 'text', ...
              'Units', 'normalized', ...
              'String', '📊 请选择需要分析的信号:', ...
              'Position', [0.03, 0.90, 0.60, 0.06], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'ForegroundColor', [0.00, 0.45, 0.74], ...
              'BackgroundColor', [0.98, 0.99, 0.98]);
    
    % 快速操作按钮
    uicontrol('Parent', signalPanel, ...
              'Style', 'pushbutton', ...
              'Units', 'normalized', ...
              'String', '✅ 全选', ...
              'Position', [0.03, 0.83, 0.28, 0.06], ...
              'Callback', {@selectAllSignals, handles}, ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.90, 1.00, 0.90]);
    
    uicontrol('Parent', signalPanel, ...
              'Style', 'pushbutton', ...
              'Units', 'normalized', ...
              'String', '❌ 取消选择', ...
              'Position', [0.33, 0.83, 0.28, 0.06], ...
              'Callback', {@deselectAllSignals, handles}, ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [1.00, 0.90, 0.90]);
    
    % 信号列表
    uicontrol('Parent', signalPanel, ...
              'Style', 'text', ...
              'Units', 'normalized', ...
              'String', '可选信号 (多选):', ...
              'Position', [0.03, 0.77, 0.60, 0.05], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.98, 0.99, 0.98]);
    
    handles.signalList = uicontrol('Parent', signalPanel, ...
                                  'Style', 'listbox', ...
                                  'Units', 'normalized', ...
                                  'Position', [0.03, 0.49, 0.58, 0.28], ...
                                  'FontSize', 9, ...
                                  'String', preset_signals, ...
                                  'Max', 10, ...
                                  'Min', 0, ...
                                  'Enable', 'on', ...
                                  'BackgroundColor', 'white', ...
                                  'Callback', {@selectSignalItem, handles});
    
    % === 分析控制区域 ===
    % 分析控制标题
    uicontrol('Parent', signalPanel, ...
              'Style', 'text', ...
              'Units', 'normalized', ...
              'String', '🚀 分析控制', ...
              'Position', [0.03, 0.44, 0.40, 0.06], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 10, ...
              'FontWeight', 'bold', ...
              'ForegroundColor', [0.80, 0.40, 0.10], ...
              'BackgroundColor', [0.98, 0.99, 0.98]);
    
    % 执行分析按钮 - 移到中间栏
    handles.runAnalysisBtn = uicontrol('Parent', signalPanel, ...
                                      'Style', 'pushbutton', ...
                                      'Units', 'normalized', ...
                                      'String', '🚀 开始分析', ...
                                      'Position', [0.03, 0.33, 0.58, 0.09], ...
                                      'FontSize', 12, ...
                                      'FontWeight', 'bold', ...
                                      'BackgroundColor', [0.10, 0.60, 0.10], ...
                                      'ForegroundColor', 'white', ...
                                      'Callback', {@runAnalysis, handles});
    
    % 停止分析按钮
    handles.stopAnalysisBtn = uicontrol('Parent', signalPanel, ...
                                       'Style', 'pushbutton', ...
                                       'Units', 'normalized', ...
                                       'String', '⏹️ 停止', ...
                                       'Position', [0.03, 0.26, 0.58, 0.07], ...
                                       'FontSize', 10, ...
                                       'FontWeight', 'bold', ...
                                       'BackgroundColor', [0.80, 0.20, 0.20], ...
                                       'ForegroundColor', 'white', ...
                                       'Enable', 'off', ...
                                       'Callback', {@stopAnalysis, handles});
    
    % 分析状态显示
    uicontrol('Parent', signalPanel, ...
              'Style', 'text', ...
              'Units', 'normalized', ...
              'String', '📊 当前状态:', ...
              'Position', [0.03, 0.21, 0.30, 0.05], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.98, 0.99, 0.98]);
    
    handles.statusText = uicontrol('Parent', signalPanel, ...
                                  'Style', 'text', ...
                                  'Units', 'normalized', ...
                                  'String', '✅ 就绪', ...
                                  'Position', [0.34, 0.21, 0.27, 0.05], ...
                                  'HorizontalAlignment', 'left', ...
                                  'FontSize', 9, ...
                                  'FontWeight', 'bold', ...
                                  'ForegroundColor', [0, 0.6, 0], ...
                                  'BackgroundColor', [0.98, 0.99, 0.98]);
    
    % 进度条 - 移到中间栏
    handles.progressBar = axes('Parent', signalPanel, ...
                              'Position', [0.04, 0.12, 0.92, 0.07], ...
                              'XLim', [0, 1], ...
                              'YLim', [0, 1], ...
                              'XTick', [], ...
                              'YTick', [], ...
                              'Box', 'on');
    
end

%% 选择信号项回调函数
function selectSignalItem(~, ~, handles)
    % 当用户选择信号列表中的项时触发
    handles = get(handles.fig, 'UserData');
    
    % 获取当前选中的信号项
    selection = get(handles.signalList, 'Value');
    signal_list = get(handles.signalList, 'String');
    
    if isempty(signal_list) || isempty(selection) || any(selection > length(signal_list)) || any(selection == 0)
        return;
    end
    
    % 可以在这里添加其他处理逻辑，比如更新状态等
    % 目前只是简单的选择处理，不显示详情
end

%% 选择所有信号
function selectAllSignals(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    % 获取信号列表中的所有项
    signal_list = get(handles.signalList, 'String');
    
    % 如果列表为空，直接返回
    if isempty(signal_list) || (length(signal_list) == 1 && strcmp(signal_list{1}, '(无可用信号)'))
        return;
    end
    
    % 选择所有项
    all_indices = 1:length(signal_list);
    set(handles.signalList, 'Value', all_indices);
    
    gui_utils('addLog', handles, '已选择所有信号');
end

%% 取消选择所有信号
function deselectAllSignals(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    % 取消所有选择
    set(handles.signalList, 'Value', []);
    
    gui_utils('addLog', handles, '已取消选择所有信号');
end

%% 运行分析
function runAnalysis(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    % 检查数据
    if isempty(handles.data)
        msgbox('请先导入仿真数据', '错误', 'error');
        return;
    end
    
    % 检查配置
    if isempty(handles.config)
        msgbox('配置错误，请检查配置设置', '错误', 'error');
        return;
    end
    
    % 更新UI状态
    set(handles.runAnalysisBtn, 'Enable', 'off');
    set(handles.stopAnalysisBtn, 'Enable', 'on');
    set(handles.statusText, 'String', '分析进行中...', 'ForegroundColor', [0.8, 0.4, 0]);
    
    % 初始化进度条
    updateProgressBar(handles, 0, '开始分析...');
    
    gui_utils('addLog', handles, '=== 开始悬架分析 ===');
    gui_utils('addLog', handles, sprintf('数据集数量: %d', length(handles.data)));
    gui_utils('addLog', handles, sprintf('输出文件夹: %s', handles.config.output_folder));
    
    try
        % 执行分析
        updateProgressBar(handles, 0.1, '准备分析...');
        
        % 获取用户选择的信号
        selected_signals = get(handles.signalList, 'Value');
        signal_list = get(handles.signalList, 'String');
        
        % 如果没有选择信号，默认分析所有信号
        if isempty(selected_signals)
            selected_signals = 1:length(signal_list);
        end
        
        % 创建自定义配置，只包含选定的信号
        custom_config = handles.config;
        
        % 传递图例配置（如果存在）
        if isfield(handles, 'current_legend_config')
            custom_config.current_legend_config = handles.current_legend_config;
            gui_utils('addLog', handles, '应用自定义图例配置');
        end
        
        % 如果有选定的信号，从配置中获取对应的信号定义
        if ~isempty(selected_signals)
            % 构建新的分析信号配置
            custom_analysis_signals = {};
            for i = 1:length(selected_signals)
                signal_idx = selected_signals(i);
                if signal_idx <= length(signal_list)
                    signal_name = signal_list{signal_idx};
                    
                    % 从完整配置中查找信号定义
                    full_config = suspension_analysis_config(custom_config.model_type);
                    found_signal = [];
                    
                    % 在配置中查找对应的信号定义
                    for k = 1:length(full_config.analysis_signals)
                        config_signal = full_config.analysis_signals{k};
                        % 检查中文标签是否匹配
                        if strcmp(config_signal{4}, signal_name)
                            found_signal = config_signal;
                            break;
                        end
                    end
                    
                    % 如果在配置中找到了匹配的信号，使用配置中的定义
                    if ~isempty(found_signal)
                        custom_analysis_signals{end+1} = found_signal;
                    else
                        % 如果没有找到，创建一个默认的信号定义
                        english_label = signal_name;
                        unit = '';
                        
                        if contains(signal_name, '加速度')
                            english_label = 'Acceleration';
                            unit = 'm/s²';
                        elseif contains(signal_name, '行程') || contains(signal_name, '位移')
                            english_label = 'Deflection';
                            unit = 'm';
                        elseif contains(signal_name, '速度')
                            english_label = 'Velocity';
                            unit = 'm/s';
                        end
                        
                        signal_entry = {signal_name, 'outputs', signal_idx, signal_name, english_label, unit};
                        custom_analysis_signals{end+1} = signal_entry;
                    end
                end
            end
            
            % 更新配置中的分析信号
            if ~isempty(custom_analysis_signals)
                custom_config.analysis_signals = custom_analysis_signals;
            end
        end
        
        % 将“数据顺序”下拉选择应用到本次分析配置（若存在该模块）
        try
            dom = struct();
            if isfield(handles, 'firstDataDropdown') && ishandle(handles.firstDataDropdown)
                fiVal = get(handles.firstDataDropdown, 'Value');
                if ~isempty(fiVal) && fiVal > 1
                    dom.first_index = fiVal - 1; % 转为1-based索引
                end
            end
            if isfield(handles, 'lastDataDropdown') && ishandle(handles.lastDataDropdown)
                liVal = get(handles.lastDataDropdown, 'Value');
                if ~isempty(liVal) && liVal > 1
                    dom.last_index = liVal - 1; % 转为1-based索引
                end
            end
            % 读取自定义顺序（若启用）
            if isfield(handles, 'enableCustomOrderCheck') && get(handles.enableCustomOrderCheck,'Value') == 1 ...
                    && isfield(handles, 'customOrderList') && ishandle(handles.customOrderList)
                ord = get(handles.customOrderList, 'UserData');
                if isnumeric(ord) && ~isempty(ord)
                    custom_config.data_order_list = ord(:)';
                    handles.config.data_order_list = ord(:)';
                    gui_utils('addLog', handles, sprintf('应用自定义顺序: [%s]', num2str(ord)));
                end
            end
            if ~isempty(fieldnames(dom))
                custom_config.data_order_mapping = dom;    % 本次分析使用
                handles.config.data_order_mapping = dom;   % 同步保存到全局配置
                gui_utils('addLog', handles, sprintf('应用数据顺序: first=%s, last=%s', ...
                    ternaryStr(isfield(dom,'first_index'), num2str(dom.first_index), '默认'), ...
                    ternaryStr(isfield(dom,'last_index'), num2str(dom.last_index), '默认')));
            end
        catch ME
            gui_utils('addLog', handles, sprintf('应用数据顺序失败: %s', ME.message));
        end

        % 调用分析工具
        suspension_analysis_tool(handles.data, handles.labels, 'Config', custom_config);
        
        updateProgressBar(handles, 1.0, '分析完成');
        
        % 更新结果显示 — 使用本次分析的输出目录
        try
            handles.results_folder = custom_config.output_folder;
        catch
            handles.results_folder = handles.config.output_folder; % 回退
        end
        if isfield(handles, 'resultsFolderText')
            set(handles.resultsFolderText, 'String', handles.results_folder);
        end
        
        % 刷新结果列表
        if isfield(handles, 'resultsFileList')
            gui_utils('refreshResultsList', handles);
        end
        
        gui_utils('addLog', handles, '=== 分析完成 ===');
        gui_utils('addLog', handles, sprintf('结果已保存至: %s', handles.results_folder));
        
        % 显示完成对话框
        msgbox(sprintf('分析完成！\n结果已保存至: %s', handles.results_folder), ...
               '分析完成', 'help');
        
        set(handles.statusText, 'String', '分析完成', 'ForegroundColor', [0, 0.6, 0]);
        
    catch ME
        updateProgressBar(handles, 0, '分析失败');
        gui_utils('addLog', handles, sprintf('分析失败: %s', ME.message));
        
        % 显示详细错误信息
        if ~isempty(ME.stack)
            gui_utils('addLog', handles, sprintf('错误位置: %s (第%d行)', ME.stack(1).file, ME.stack(1).line));
        end
        
        msgbox(sprintf('分析失败！\n错误信息: %s', ME.message), '错误', 'error');
        set(handles.statusText, 'String', '分析失败', 'ForegroundColor', [0.8, 0.2, 0.2]);
    end
    
    % 恢复UI状态
    set(handles.runAnalysisBtn, 'Enable', 'on');
    set(handles.stopAnalysisBtn, 'Enable', 'off');
    
    % 保存handles
    set(handles.fig, 'UserData', handles);
end

%% 停止分析
function stopAnalysis(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    gui_utils('addLog', handles, '用户请求停止分析');
    set(handles.statusText, 'String', '正在停止...', 'ForegroundColor', [0.8, 0.4, 0]);
    
    % 恢复UI状态
    set(handles.runAnalysisBtn, 'Enable', 'on');
    set(handles.stopAnalysisBtn, 'Enable', 'off');
    
    updateProgressBar(handles, 0, '已停止');
    set(handles.statusText, 'String', '已停止', 'ForegroundColor', [0.6, 0.6, 0.6]);
end

%% 更新进度条
function updateProgressBar(handles, progress, message)
    axes(handles.progressBar);
    cla;
    
    % 绘制进度条
    rectangle('Position', [0, 0.2, progress, 0.6], ...
             'FaceColor', [0.2, 0.6, 1], ...
             'EdgeColor', 'none');
    
    rectangle('Position', [0, 0.2, 1, 0.6], ...
             'FaceColor', 'none', ...
             'EdgeColor', 'black', ...
             'LineWidth', 1);
    
    % 添加进度文本
    text(0.5, 0.5, sprintf('%.0f%% - %s', progress*100, message), ...
         'HorizontalAlignment', 'center', ...
         'VerticalAlignment', 'middle', ...
         'FontSize', 8);
    
    drawnow;
end

%% 更新信号列表
function updateSignalList(model_type, handles) %#ok<DEFNU>
    % 根据模型类型更新信号列表
    if nargin < 1 || isempty(model_type)
        model_type = 'half';
    end
    
    handles = get(handles.fig, 'UserData');
    
    % 总是展示预设信号（即使还未导入数据）
    set(handles.signalList, 'Enable', 'on');
    
    % 根据模型类型获取信号列表
    preset_signals = getSignalListByModelType(model_type);
    
    % 更新信号列表
    set(handles.signalList, 'String', preset_signals);
    set(handles.signalList, 'Value', []); % 清除当前选择
    
    gui_utils('addLog', handles, sprintf('已更新%s模型信号列表，共 %d 个信号', ...
        getModelTypeName(model_type), length(preset_signals)));
    
    % 保存handles
    set(handles.fig, 'UserData', handles);
end

%% 根据模型类型获取信号列表
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
        warning('SIGNAL:ConfigError', '获取信号配置失败: %s', ME.message);
        % 使用默认信号列表
        signals = getDefaultSignals(model_type);
    end
end

%% 获取默认信号列表（备用方案）
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
        case 'full'
            signals = {
                '车身质心垂向加速度',
                '车身质心垂向位移',
                '车身质心垂向速度',
                '俯仰角加速度',
                '俯仰角',
                '俯仰角速度',
                '侧倾角加速度',
                '侧倾角',
                '侧倾角速度',
                '左前非簧载质量加速度',
                '右前非簧载质量加速度',
                '左后非簧载质量加速度',
                '右后非簧载质量加速度',
                '左前悬架动行程',
                '右前悬架动行程',
                '左后悬架动行程',
                '右后悬架动行程',
                '左前轮胎动变形',
                '右前轮胎动变形',
                '左后轮胎动变形',
                '右后轮胎动变形'
            };
        otherwise
            signals = {'(无可用信号)'};
    end
end

%% 获取模型类型的中文名称
function name = getModelTypeName(model_type)
    switch lower(model_type)
        case 'half'
            name = '半车';
        case 'quarter'
            name = '四分之一车';
        case 'full'
            name = '整车';
        otherwise
            name = '未知';
    end
end

%% 简单三元字符串帮助函数（仅本文件内部使用）
function out = ternaryStr(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end