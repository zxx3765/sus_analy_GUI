function main_gui()
%% 悬架分析GUI - 主界面框架
% 模块化设计的主界面，调用各功能模块
%
% 功能包括:
% - 数据导入和预览
% - 分析配置管理
% - 信号选择和分析控制
% - 结果查看和管理
%
% 作者: Claude Code Assistant
% 日期: 2024

%% 创建主窗口
theme = gui_theme();
fig = figure('Name', '悬架分析工具 - Suspension Analysis GUI', ...
             'NumberTitle', 'off', ...
             'Position', centeredWindowPosition(1440, 900), ...
             'Resize', 'on', ...
             'CloseRequestFcn', @closeGUI, ...
             'MenuBar', 'none', ...
             'ToolBar', 'none', ...
             'Color', theme.canvas, ...
             'Visible', 'off');

%% 全局数据存储
handles = struct();
handles.fig = fig;
handles.data = {};          % 存储导入的数据
handles.labels = {};        % 数据标签
handles.config = [];        % 当前配置
handles.results_folder = '';% 当前结果文件夹
handles.theme = theme;      % 全局视觉主题

%% 初始化默认配置（在创建布局之前）
initializeDefaultConfig(handles);

%% 创建GUI布局
handles = createMainLayout(handles);

% 在所有模块创建完成后统一应用主题，消除各模块历史配色差异。
gui_apply_theme(fig);

% 将handles存储到figure的UserData中
set(fig, 'UserData', handles);

% 使窗口可见
set(fig, 'Visible', 'on');

fprintf('悬架分析GUI已启动\n');

end

%% 创建主要布局框架
function handles = createMainLayout(handles)
    fig = handles.fig;
    theme = handles.theme;

    %% 顶层页面
    % 将原有分析布局完整放入“分析页面”，批量仿真使用独立页面，
    % 避免批量仿真控件与既有分析控件共享局部布局。
    mainTabGroup = uitabgroup('Parent', fig, ...
                             'Position', [0.008, 0.010, 0.984, 0.982]);
    analysisPage = uitab(mainTabGroup, 'Title', '分析页面', ...
                         'BackgroundColor', theme.canvas);
    batchPage = uitab(mainTabGroup, 'Title', '批量执行页面', ...
                      'BackgroundColor', theme.canvas);
    fdeiPage = uitab(mainTabGroup, 'Title', 'FDEI 分析', ...
                     'BackgroundColor', theme.canvas);
    handles.mainTabGroup = mainTabGroup;
    handles.analysisPage = analysisPage;
    handles.batchPage = batchPage;
    handles.fdeiPage = fdeiPage;
    
    %% 分析页面标题区
    analysisHeader = uipanel('Parent', analysisPage, ...
                            'BorderType', 'none', ...
                            'Position', [0.015, 0.905, 0.97, 0.075], ...
                            'BackgroundColor', theme.primary);
    uicontrol('Parent', analysisHeader, 'Style', 'text', ...
              'String', '悬架性能分析工作台', ...
              'Units', 'normalized', 'Position', [0.025, 0.34, 0.46, 0.46], ...
              'HorizontalAlignment', 'left', 'FontSize', 15, ...
              'FontWeight', 'bold', 'ForegroundColor', theme.onPrimary, ...
              'BackgroundColor', theme.primary);
    uicontrol('Parent', analysisHeader, 'Style', 'text', ...
              'String', '导入数据 · 配置指标 · 执行分析 · 查看结果', ...
              'Units', 'normalized', 'Position', [0.025, 0.08, 0.60, 0.27], ...
              'HorizontalAlignment', 'left', 'FontSize', 9, ...
              'ForegroundColor', theme.primarySoftText, ...
              'BackgroundColor', theme.primary);
    uicontrol('Parent', analysisHeader, 'Style', 'text', ...
              'String', 'ANALYSIS WORKSPACE', ...
              'Units', 'normalized', 'Position', [0.70, 0.24, 0.275, 0.40], ...
              'HorizontalAlignment', 'right', 'FontSize', 9, ...
              'FontWeight', 'bold', 'ForegroundColor', theme.primarySoftText, ...
              'BackgroundColor', theme.primary);

    analysisContent = uipanel('Parent', analysisPage, ...
                              'BorderType', 'none', ...
                              'Position', [0.005, 0.015, 0.99, 0.875], ...
                              'BackgroundColor', theme.canvas);

    %% 创建主要面板 - 三栏工作区
    leftPanel = uipanel('Parent', analysisContent, ...
                       'Title', '数据与配置', ...
                       'Position', [0.012, 0.015, 0.335, 0.97], ...
                       'FontSize', 11, ...
                       'FontWeight', 'bold', ...
                       'BackgroundColor', theme.surface);
    
    % 中间面板 - 创建选项卡组
    middleTabGroup = uitabgroup('Parent', analysisContent, ...
                               'Position', [0.357, 0.015, 0.318, 0.97]);
    
    % 信号选择选项卡
    signalTab = uitab(middleTabGroup, 'Title', '📊 信号选择');
    
    % 数据顺序设置选项卡
    orderTab = uitab(middleTabGroup, 'Title', '📈 数据顺序');

    % 数据处理选项卡
    processingTab = uitab(middleTabGroup, 'Title', '⚙️ 数据处理');
    
    % 右侧面板 - 分析和结果 (增加宽度)
    rightPanel = uipanel('Parent', analysisContent, ...
                        'Title', '日志与结果', ...
                        'Position', [0.685, 0.015, 0.303, 0.97], ...
                        'FontSize', 11, ...
                        'FontWeight', 'bold', ...
                        'BackgroundColor', theme.surface);
    
    %% 调用各模块创建函数
    handles = gui_data_manager(leftPanel, handles);
    handles = gui_config_manager(leftPanel, handles);
    handles = gui_signal_analysis(signalTab, handles);
    handles = gui_simple_data_order(orderTab, handles);  % 简化的数据顺序设置
    handles = gui_data_processing(processingTab, handles);
    handles = gui_log_viewer(rightPanel, handles);
    handles = gui_results_viewer(rightPanel, handles);

    %% 批量执行页面标题与内容区
    batchHeader = uipanel('Parent', batchPage, ...
                         'BorderType', 'none', ...
                         'Position', [0.015, 0.905, 0.97, 0.075], ...
                         'BackgroundColor', theme.primary);
    uicontrol('Parent', batchHeader, 'Style', 'text', ...
              'String', 'Simulink 批量执行中心', ...
              'Units', 'normalized', 'Position', [0.025, 0.34, 0.50, 0.46], ...
              'HorizontalAlignment', 'left', 'FontSize', 15, ...
              'FontWeight', 'bold', 'ForegroundColor', theme.onPrimary, ...
              'BackgroundColor', theme.primary);
    uicontrol('Parent', batchHeader, 'Style', 'text', ...
              'String', '选择模型与工况，集中管理算法并跟踪执行状态', ...
              'Units', 'normalized', 'Position', [0.025, 0.08, 0.62, 0.27], ...
              'HorizontalAlignment', 'left', 'FontSize', 9, ...
              'ForegroundColor', theme.primarySoftText, ...
              'BackgroundColor', theme.primary);
    uicontrol('Parent', batchHeader, 'Style', 'text', ...
              'String', 'BATCH SIMULATION', ...
              'Units', 'normalized', 'Position', [0.70, 0.24, 0.275, 0.40], ...
              'HorizontalAlignment', 'right', 'FontSize', 9, ...
              'FontWeight', 'bold', 'ForegroundColor', theme.primarySoftText, ...
              'BackgroundColor', theme.primary);
    batchContent = uipanel('Parent', batchPage, ...
                           'BorderType', 'none', ...
                           'Position', [0.005, 0.015, 0.99, 0.875], ...
                           'BackgroundColor', theme.canvas);

    % 批量执行页面。该模块自行管理批量页面状态，但仍将状态保存到
    % figure.UserData，确保与已有模块的回调取值方式一致。
    handles = gui_batch_execution(batchContent, handles);

    %% FDEI 分析页面：批量仿真与分析绘图两个子页
    handles = gui_fdei_analysis(fdeiPage, handles);
    
    % 初始刷新一次“数据顺序”下拉（若存在数据则显示全部项）
    try
        if exist('updateSimpleDataOrderDropdowns', 'file') == 2
            updateSimpleDataOrderDropdowns(handles);
        end
        if exist('updateCustomOrderList', 'file') == 2
            updateCustomOrderList(handles);
        end
    catch
        % 忽略初始化刷新失败
    end
    
end

%% 初始化默认配置
function initializeDefaultConfig(handles)
    try
        config = quick_config('half', 'cn', true);
        handles.config = config;
        
        % 更新GUI控件状态
        updateGUIFromConfig(handles);
        
        % 更新结果文件夹显示
        if isfield(handles, 'resultsFolderText')
            set(handles.resultsFolderText, 'String', config.output_folder);
        end
        handles.results_folder = config.output_folder;
        
        addLog(handles, '默认配置已加载');
    catch ME
        addLog(handles, sprintf('配置初始化失败: %s', ME.message));
        % 创建最小配置
        handles.config = struct();
        handles.config.output_folder = 'results';
        handles.config.save_plots = true;
    end
    
    % 保存handles
    set(handles.fig, 'UserData', handles);
end

%% 从配置更新GUI控件
function updateGUIFromConfig(handles)
    if isempty(handles.config)
        return;
    end
    
    config = handles.config;
    
    % 模型类型
    if isfield(handles, 'modelTypePopup')
        switch config.model_type
            case 'half'
                set(handles.modelTypePopup, 'Value', 1);
            case 'quarter'
                set(handles.modelTypePopup, 'Value', 2);
            case 'full'
                set(handles.modelTypePopup, 'Value', 3);
            otherwise
                set(handles.modelTypePopup, 'Value', 1);
        end
    end
    
    % 语言
    if isfield(handles, 'languagePopup')
        if strcmp(config.language, 'cn')
            set(handles.languagePopup, 'Value', 1);
        else
            set(handles.languagePopup, 'Value', 2);
        end
    end
    
    % 保存图片
    if isfield(handles, 'savePlotsCheck')
        set(handles.savePlotsCheck, 'Value', config.save_plots);
    end
    
    % 保存.fig文件
    if isfield(config, 'save_fig_files') && isfield(handles, 'saveFigFilesCheck')
        set(handles.saveFigFilesCheck, 'Value', config.save_fig_files);
    end
    
    % 关闭图窗
    if isfield(config, 'close_figures') && isfield(handles, 'closeFiguresCheck')
        set(handles.closeFiguresCheck, 'Value', config.close_figures);
    end
    
    % 图片格式
    if isfield(handles, 'plotFormatPopup')
        formats = {'png', 'eps', 'pdf'};
        format_idx = find(strcmp(config.plot_format, formats), 1);
        if ~isempty(format_idx)
            set(handles.plotFormatPopup, 'Value', format_idx);
        end
    end
    
    % 时间戳文件夹
    if isfield(config, 'use_timestamp_folder') && isfield(handles, 'useTimestampCheck')
        set(handles.useTimestampCheck, 'Value', config.use_timestamp_folder);
        if config.use_timestamp_folder && isfield(handles, 'outputFolderEdit')
            set(handles.outputFolderEdit, 'Enable', 'off');
        elseif isfield(handles, 'outputFolderEdit')
            set(handles.outputFolderEdit, 'Enable', 'on');
            set(handles.outputFolderEdit, 'String', config.output_folder);
        end
    end
    
    % 分析选项
    if isfield(config, 'analysis')
        if isfield(handles, 'freqAnalysisCheck')
            set(handles.freqAnalysisCheck, 'Value', config.analysis.frequency_response);
        end
        if isfield(handles, 'timeAnalysisCheck')
            set(handles.timeAnalysisCheck, 'Value', config.analysis.time_domain);
        end
        if isfield(handles, 'rmsAnalysisCheck')
            set(handles.rmsAnalysisCheck, 'Value', config.analysis.rms_comparison);
        end
        if isfield(handles, 'statAnalysisCheck')
            set(handles.statAnalysisCheck, 'Value', config.analysis.statistical);
        end
        if isfield(handles, 'bandRmsAnalysisCheck')
            if isfield(config.analysis, 'band_rms')
                set(handles.bandRmsAnalysisCheck, 'Value', config.analysis.band_rms);
            else
                set(handles.bandRmsAnalysisCheck, 'Value', 0);
            end
        end
    end
    
    % 参考频率
    if isfield(config, 'plot') && isfield(config.plot, 'reference_lines') && isfield(handles, 'refFreqEdit')
        if ~isempty(config.plot.reference_lines)
            ref_str = sprintf('%.1f, ', config.plot.reference_lines);
            ref_str = ref_str(1:end-2); % 移除最后的逗号和空格
            set(handles.refFreqEdit, 'String', ref_str);
        end
    end
    
    % 数据顺序映射
    if isfield(config, 'data_order_mapping')
        if isfield(config.data_order_mapping, 'first_index') && isfield(handles, 'firstDataDropdown')
            set(handles.firstDataDropdown, 'Value', config.data_order_mapping.first_index + 1);
        end
        if isfield(config.data_order_mapping, 'last_index') && isfield(handles, 'lastDataDropdown')
            set(handles.lastDataDropdown, 'Value', config.data_order_mapping.last_index + 1);
        end
    end
end

%% 添加日志工具函数
function addLog(handles, message)
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

%% 关闭GUI
function closeGUI(~, ~)
    selection = questdlg('确定要关闭悬架分析GUI吗？', ...
                        '确认关闭', ...
                        '是', '否', '否');
    
    if strcmp(selection, '是')
        delete(gcf);
    end
end

%% 根据屏幕尺寸生成居中的窗口位置
function position = centeredWindowPosition(preferredWidth, preferredHeight)
screen = get(0, 'ScreenSize');
width = min(preferredWidth, max(1050, screen(3) - 80));
height = min(preferredHeight, max(720, screen(4) - 120));
left = max(screen(1) + 20, screen(1) + (screen(3) - width) / 2);
bottom = max(screen(2) + 40, screen(2) + (screen(4) - height) / 2);
position = round([left, bottom, width, height]);
end
