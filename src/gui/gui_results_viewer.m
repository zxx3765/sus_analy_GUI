function handles = gui_results_viewer(parent, handles)
%% 结果查看器模块
% 负责分析结果的查看和管理
%
% 功能:
% - 结果文件夹管理
% - 结果文件列表显示
% - 文件预览和查看
% - 文件操作 (打开、刷新)
%
% 输入:
%   parent - 父容器对象
%   handles - GUI句柄结构体
%
% 输出:  
%   handles - 更新后的句柄结构体

    % 结果查看面板 - 优化布局
    resultsPanel = uipanel('Parent', parent, ...
                          'Title', '📈 结果查看', ...
                          'Units', 'normalized', ...
                          'Position', [0.02, 0.02, 0.96, 0.51], ...
                          'FontSize', 10, ...
                          'FontWeight', 'bold', ...
                          'BackgroundColor', [0.98, 0.99, 0.98], ...
                          'ForegroundColor', [0.10, 0.50, 0.80]);
    
    % 结果文件夹显示 - 优化布局
    uicontrol('Parent', resultsPanel, ...
              'Style', 'text', ...
              'Units', 'normalized', ...
              'String', '📁 结果文件夹:', ...
              'Position', [0.03, 0.90, 0.30, 0.08], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.98, 0.99, 0.98]);
    
    handles.resultsFolderText = uicontrol('Parent', resultsPanel, ...
                                         'Style', 'edit', ...
                                         'Units', 'normalized', ...
                                         'Position', [0.03, 0.83, 0.70, 0.08], ...
                                         'FontSize', 8, ...
                                         'BackgroundColor', [0.95, 0.95, 0.95], ...
                                         'Enable', 'off');
    
    uicontrol('Parent', resultsPanel, ...
              'Style', 'pushbutton', ...
              'String', '📂 打开', ...
              'Units', 'normalized', ...
              'Position', [0.75, 0.83, 0.20, 0.08], ...
              'FontSize', 8, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.90, 0.95, 1.00], ...
              'Callback', {@openResultsFolder, handles});
    
    % 结果文件列表 - 扩大显示区域
    uicontrol('Parent', resultsPanel, ...
              'Style', 'text', ...
              'Units', 'normalized', ...
              'String', '📄 生成的文件:', ...
              'Position', [0.03, 0.76, 0.30, 0.06], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 9, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.98, 0.99, 0.98]);
    
    handles.resultsFileList = uicontrol('Parent', resultsPanel, ...
                                       'Style', 'listbox', ...
                                       'Units', 'normalized', ...
                                       'Position', [0.03, 0.06, 0.70, 0.68], ...
                                       'FontSize', 8, ...
                                       'BackgroundColor', 'white', ...
                                       'Callback', {@selectResultFile, handles}, ...
                                       'KeyPressFcn', {@fileListKeyPress, handles});
    
    % 文件操作按钮 - 重新布局
    uicontrol('Parent', resultsPanel, ...
              'Style', 'pushbutton', ...
              'String', '👁️ 打开文件', ...
              'Units', 'normalized', ...
              'Position', [0.75, 0.48, 0.20, 0.12], ...
              'FontSize', 8, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [0.90, 1.00, 0.90], ...
              'Callback', {@viewSelectedFile, handles});
    
    uicontrol('Parent', resultsPanel, ...
              'Style', 'pushbutton', ...
              'String', '🔄 刷新列表', ...
              'Units', 'normalized', ...
              'Position', [0.75, 0.33, 0.20, 0.12], ...
              'FontSize', 8, ...
              'FontWeight', 'bold', ...
              'BackgroundColor', [1.00, 0.98, 0.90], ...
              'Callback', {@refreshResultsListWrapper, handles});
    
    % 操作说明
    uicontrol('Parent', resultsPanel, ...
              'Style', 'text', ...
              'String', '💡 操作提示: 选择文件后点击"打开文件"按钮或按Enter键直接查看文件', ...
              'Units', 'normalized', ...
              'Position', [0.75, 0.10, 0.22, 0.20], ...
              'HorizontalAlignment', 'left', ...
              'FontSize', 7, ...
              'ForegroundColor', [0.50, 0.50, 0.50], ...
              'BackgroundColor', [0.98, 0.99, 0.98]);

end

%% 文件列表键盘事件处理
function fileListKeyPress(~, eventdata, handles)
    handles = get(handles.fig, 'UserData');
    
    % 检查是否按下了Enter键
    if strcmp(eventdata.Key, 'return')
        viewSelectedFile([], [], handles);
    end
end

%% 刷新结果列表包装函数
function refreshResultsListWrapper(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    gui_utils('refreshResultsList', handles);
end

%% 查看选中文件
function viewSelectedFile(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    selection = get(handles.resultsFileList, 'Value');
    file_list = get(handles.resultsFileList, 'String');
    
    if isempty(file_list) || selection > length(file_list)
        return;
    end
    
    selected_file = file_list{selection};
    
    % 跳过分类标题
    if startsWith(selected_file, '---')
        return;
    end
    
    file_path = fullfile(handles.results_folder, selected_file);
    
    if ~exist(file_path, 'file')
        gui_utils('addLog', handles, sprintf('文件不存在: %s', selected_file));
        return;
    end
    
    [~, ~, ext] = fileparts(selected_file);
    
    % 统一处理：所有文件都用系统默认程序打开
    try
        if ispc
            winopen(file_path);
        elseif ismac
            system(['open "' file_path '"']);
        else
            system(['xdg-open "' file_path '"']);
        end
        gui_utils('addLog', handles, sprintf('已打开文件: %s', selected_file));
        
        % 根据文件类型显示相应的提示信息
        switch lower(ext)
            case {'.png', '.jpg', '.jpeg'}
                gui_utils('addLog', handles, '  → 图片文件已在默认图片查看器中打开');
            case {'.eps', '.pdf'}
                gui_utils('addLog', handles, '  → 文档文件已在默认应用中打开');
            case '.mat'
                gui_utils('addLog', handles, '  → MATLAB数据文件，建议在MATLAB中加载查看');
            case '.txt'
                gui_utils('addLog', handles, '  → 文本文件已在默认编辑器中打开');
            otherwise
                gui_utils('addLog', handles, '  → 文件已在默认应用中打开');
        end
        
    catch ME
        gui_utils('addLog', handles, sprintf('无法打开文件 %s: %s', selected_file, ME.message));
        
        % 如果系统打开失败，对于MAT文件提供备选方案
        if strcmpi(ext, '.mat')
            try
                loaded_data = load(file_path);
                field_names = fieldnames(loaded_data);
                assignin('base', 'loaded_results', loaded_data);
                
                msg = sprintf('文件已加载到工作空间变量 "loaded_results"\n包含字段: %s', ...
                             strjoin(field_names, ', '));
                msgbox(msg, selected_file, 'help');
                gui_utils('addLog', handles, sprintf('已将数据文件加载到工作空间: %s', selected_file));
            catch ME2
                gui_utils('addLog', handles, sprintf('无法加载数据文件 %s: %s', selected_file, ME2.message));
            end
        end
    end
end

%% 选择结果文件
function selectResultFile(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    selection = get(handles.resultsFileList, 'Value');
    file_list = get(handles.resultsFileList, 'String');
    
    if isempty(file_list) || selection > length(file_list)
        return;
    end
    
    selected_file = file_list{selection};
    
    % 跳过分类标题
    if startsWith(selected_file, '---')
        return;
    end
    
    % 显示选中文件的信息
    [~, ~, ext] = fileparts(selected_file);
    switch lower(ext)
        case {'.png', '.jpg', '.jpeg'}
            gui_utils('addLog', handles, sprintf('已选择图片文件: %s', selected_file));
        case {'.eps', '.pdf'} 
            gui_utils('addLog', handles, sprintf('已选择文档文件: %s', selected_file));
        case '.mat'
            gui_utils('addLog', handles, sprintf('已选择数据文件: %s', selected_file));
        case '.txt'
            gui_utils('addLog', handles, sprintf('已选择文本文件: %s', selected_file));
        otherwise
            gui_utils('addLog', handles, sprintf('已选择文件: %s', selected_file));
    end
end

%% 打开结果文件夹
function openResultsFolder(~, ~, handles)
    handles = get(handles.fig, 'UserData');
    
    if isempty(handles.results_folder) || ~exist(handles.results_folder, 'dir')
        msgbox('结果文件夹不存在', '提示', 'warn');
        return;
    end
    
    try
        if ispc
            winopen(handles.results_folder);
        elseif ismac
            system(['open "' handles.results_folder '"']);
        else
            system(['xdg-open "' handles.results_folder '"']);
        end
        gui_utils('addLog', handles, sprintf('已打开结果文件夹: %s', handles.results_folder));
    catch ME
        gui_utils('addLog', handles, sprintf('无法打开文件夹: %s', ME.message));
    end
end