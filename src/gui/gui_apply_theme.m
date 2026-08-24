function gui_apply_theme(root)
%% GUI_APPLY_THEME 将统一主题应用到指定 GUI 层级
% 仅调整视觉属性，不修改控件位置、状态、回调或业务数据。

if nargin < 1 || isempty(root) || ~ishandle(root)
    return;
end

theme = gui_theme();
objects = findall(root);
for index = 1:numel(objects)
    object = objects(index);
    try
        objectType = get(object, 'Type');
    catch
        continue;
    end

    switch lower(objectType)
        case 'figure'
            safeSet(object, 'Color', theme.canvas);

        case 'uipanel'
            titleText = safeGet(object, 'Title', '');
            if ~isempty(titleText)
                safeSet(object, 'BackgroundColor', theme.surface);
                safeSet(object, 'ForegroundColor', theme.primary);
                safeSet(object, 'FontName', theme.font);
                safeSet(object, 'HighlightColor', theme.border);
            end

        case {'uitab', 'uitabgroup'}
            safeSet(object, 'BackgroundColor', theme.canvas);
            safeSet(object, 'FontName', theme.font);
            safeSet(object, 'ForegroundColor', theme.text);

        case 'uitable'
            safeSet(object, 'FontName', theme.font);
            safeSet(object, 'FontSize', 9);
            safeSet(object, 'ForegroundColor', theme.text);
            safeSet(object, 'BackgroundColor', ...
                [theme.surface; theme.surfaceAlt]);

        case 'axes'
            safeSet(object, 'Color', theme.surfaceAlt);
            safeSet(object, 'XColor', theme.border);
            safeSet(object, 'YColor', theme.border);

        case 'uicontrol'
            applyControlTheme(object, theme);
    end
end
end

function applyControlTheme(control, theme)
style = lower(safeGet(control, 'Style', ''));
originalFont = safeGet(control, 'FontName', '');
safeSet(control, 'FontName', theme.font);

switch style
    case 'text'
        background = parentBackground(control, theme);
        safeSet(control, 'BackgroundColor', background);
        safeSet(control, 'ForegroundColor', readableTextColor(background, theme));

    case {'edit', 'popupmenu', 'listbox'}
        isConsole = strcmpi(originalFont, theme.monoFont) || ...
            strcmpi(safeGet(control, 'Tag', ''), ...
            'ConsoleLog');
        if isConsole
            safeSet(control, 'FontName', theme.monoFont);
            safeSet(control, 'BackgroundColor', theme.console);
            safeSet(control, 'ForegroundColor', theme.consoleText);
        else
            safeSet(control, 'BackgroundColor', theme.input);
            safeSet(control, 'ForegroundColor', theme.text);
        end

    case {'checkbox', 'radiobutton'}
        background = parentBackground(control, theme);
        safeSet(control, 'BackgroundColor', background);
        safeSet(control, 'ForegroundColor', readableTextColor(background, theme));

    case 'pushbutton'
        label = controlLabel(control);
        safeSet(control, 'BackgroundColor', theme.surfaceAlt);
        safeSet(control, 'ForegroundColor', theme.text);

        if containsAny(label, {'开始分析', '批量执行', ...
                '执行截断', '应用设置', '确定'})
            safeSet(control, 'BackgroundColor', theme.primaryHover);
            safeSet(control, 'ForegroundColor', theme.onPrimary);
            safeSet(control, 'FontWeight', 'bold');
        elseif containsAny(label, {'新增', '导入', '浏览', ...
                '打开', '预览', '智能设置'})
            safeSet(control, 'BackgroundColor', theme.primarySoft);
            safeSet(control, 'ForegroundColor', theme.primary);
        elseif containsAny(label, {'全选', '刷新'})
            safeSet(control, 'BackgroundColor', theme.successSoft);
            safeSet(control, 'ForegroundColor', theme.success);
        elseif containsAny(label, {'停止', '删除', '删选中', '清空'})
            safeSet(control, 'BackgroundColor', theme.dangerSoft);
            safeSet(control, 'ForegroundColor', theme.danger);
        end
end
end

function color = readableTextColor(background, theme)
% 标题带等深色容器自动使用浅色文字。
luminance = 0.2126 * background(1) + 0.7152 * background(2) + ...
    0.0722 * background(3);
if luminance < 0.55
    color = theme.onPrimary;
else
    color = theme.text;
end
end

function label = controlLabel(control)
value = safeGet(control, 'String', '');
if iscell(value)
    label = strjoin(value, ' ');
elseif isstring(value)
    label = char(strjoin(value, ' '));
elseif ischar(value)
    label = value;
else
    label = '';
end
end

function result = containsAny(value, patterns)
result = false;
for index = 1:numel(patterns)
    if contains(value, patterns{index})
        result = true;
        return;
    end
end
end

function color = parentBackground(control, theme)
color = theme.surface;
try
    parent = get(control, 'Parent');
    if ishandle(parent) && isprop(parent, 'BackgroundColor')
        candidate = get(parent, 'BackgroundColor');
        if isnumeric(candidate) && numel(candidate) == 3
            color = candidate;
        end
    end
catch
end
end

function value = safeGet(object, property, fallback)
value = fallback;
try
    value = get(object, property);
catch
end
end

function safeSet(object, property, value)
try
    set(object, property, value);
catch
end
end
