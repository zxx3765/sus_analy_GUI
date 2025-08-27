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

    % 预设信号列表
    preset_signals = {
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
    
    % 信号选择面板 - 重新设计布局，包含分析控制
    signalPanel = uipanel('Parent', parent, ...
                         'Title', '⚙️ 信号选择 & 分析控制', ...
                         'Position', [0.02, 0.02, 0.96, 0.96], ...
                         'FontSize', 10, ...
                         'FontWeight', 'bold', ...
                         'BackgroundColor', [0.97, 0.97, 0.97], ...
                         'ForegroundColor', [0.6, 0.3, 0.1]);
    
    % === 信号选择区域 ===
    % 添加说明文字
    uicontrol('Parent', signalPanel, ...
              'Style', 'text', ...
              'String', '📊 请选择需要分析的信号:', ...
              'Position', [15, 680, 200, 20], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'ForegroundColor', [0, 0, 1]);
    
    % 快速操作按钮
    uicontrol('Parent', signalPanel, ...
              'Style', 'pushbutton', ...
              'String', '✅ 全选', ...
              'Position', [15, 650, 80, 28], ...
              'Callback', {@selectAllSignals, handles}, ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.9, 1, 0.9]);
    
    uicontrol('Parent', signalPanel, ...
              'Style', 'pushbutton', ...
              'String', '❌ 取消选择', ...
              'Position', [105, 650, 80, 28], ...
              'Callback', {@deselectAllSignals, handles}, ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [1, 0.9, 0.9]);
    
    % 信号列表
    uicontrol('Parent', signalPanel, ...
              'Style', 'text', ...
              'String', '可选信号 (多选):', ...
              'Position', [15, 625, 120, 18], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    handles.signalList = uicontrol('Parent', signalPanel, ...
                                  'Style', 'listbox', ...
                                  'Position', [15, 480, 210, 140], ...
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
              'String', '🚀 分析控制', ...
              'Position', [15, 440, 100, 20], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 10, ...
              'FontWeight', 'bold', ...
              'ForegroundColor', [0.8, 0.4, 0.1]);
    
    % 执行分析按钮 - 移到中间栏
    handles.runAnalysisBtn = uicontrol('Parent', signalPanel, ...
                                      'Style', 'pushbutton', ...
                                      'String', '🚀 开始分析', ...
                                      'Position', [15, 350, 210, 50], ...
                                      'FontSize', 12, ...
                                      'FontWeight', 'bold', ...
                                      'BackgroundColor', [0.1, 0.6, 0.1], ...
                                      'ForegroundColor', 'white', ...
                                      'Callback', {@runAnalysis, handles});
    
    % 停止分析按钮
    handles.stopAnalysisBtn = uicontrol('Parent', signalPanel, ...
                                       'Style', 'pushbutton', ...
                                       'String', '⏹️ 停止', ...
                                       'Position', [15, 295, 210, 35], ...
                                       'FontSize', 10, ...
                                       'FontWeight', 'bold', ...
                                       'BackgroundColor', [0.8, 0.2, 0.2], ...
                                       'ForegroundColor', 'white', ...
                                       'Enable', 'off', ...
                                       'Callback', {@stopAnalysis, handles});
    
    % 分析状态显示
    uicontrol('Parent', signalPanel, ...
              'Style', 'text', ...
              'String', '📊 当前状态:', ...
              'Position', [15, 265, 80, 18], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold');
    
    handles.statusText = uicontrol('Parent', signalPanel, ...
                                  'Style', 'text', ...
                                  'String', '✅ 就绪', ...
                                  'Position', [100, 265, 125, 18], ...
                                  'HorizontalAlignment', 'left', ...
                                  'FontSize', 9, ...
                                  'FontWeight', 'bold', ...
                                  'ForegroundColor', [0, 0.6, 0]);
    
    % 进度条 - 移到中间栏
    handles.progressBar = axes('Parent', signalPanel, ...
                              'Position', [0.065, 0.25, 0.87, 0.08], ...
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
                            % 更新索引为当前选择的信号索引
                            found_signal{3} = signal_idx;
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
        
        % 调用分析工具
        suspension_analysis_tool(handles.data, handles.labels, 'Config', custom_config);
        
        updateProgressBar(handles, 1.0, '分析完成');
        
        % 更新结果显示
        handles.results_folder = handles.config.output_folder;
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
function updateSignalList(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    % 检查是否有数据
    if isempty(handles.data)
        set(handles.signalList, 'String', {'(无可用信号)'});
        set(handles.signalList, 'Enable', 'off');
        return;
    end
    
    % 启用信号列表
    set(handles.signalList, 'Enable', 'on');
    
    % 保持预设的信号列表不变
    preset_signals = {
        '车体垂向加速度',
        '车体俯仰角加速度',
        '前悬架动挠度',
        '后悬架动挠度',
        '前轮胎动位移',
        '后轮胎动位移'
    };
    
    % 更新信号列表为预设信号
    set(handles.signalList, 'String', preset_signals);
    gui_utils('addLog', handles, sprintf('已更新信号列表，使用预设的 %d 个信号', length(preset_signals)));
end