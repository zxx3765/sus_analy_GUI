function [figures, plotData] = fdei_plot_figures12(results, cfg, varargin)
%FDEI_PLOT_FIGURES12 Draw and optionally export FDEI Figures 1 and 2.
%   Figure 1 is the controllable damper-port Ceq/Beq/Keq. Figure 2 is the
%   total suspension impedance including the parallel spring. The optional
%   name-value 'Visible' controls figure visibility and 'OutputDir' changes
%   the export directory.

visible = 'on';
outputDir = getOption(cfg, 'analysisOutputDir', getOption(cfg, 'outputDir', pwd));
saveFigures = logical(getOption(cfg, 'saveFigures', false));
for index = 1:2:numel(varargin)
    optionName = lower(char(string(varargin{index})));
    optionValue = varargin{index+1};
    switch optionName
        case 'visible'
            visible = char(string(optionValue));
        case 'outputdir'
            outputDir = char(string(optionValue));
        case 'savefigures'
            saveFigures = logical(optionValue);
        otherwise
            error('fdei_plot_figures12:InvalidOption', ...
                '未知选项：%s。', optionName);
    end
end
if isempty(results) || ~istableSafe(results)
    error('fdei_plot_figures12:InvalidResults', 'results 必须是非空 table。');
end
strategies = unique(string(results.Strategy), 'stable');
figures = cell(2,1);
plotData = struct('damper', results, 'total', results);
figures{1} = makeFigure('Damper-port FDEI', visible);
drawMetricFigure(figures{1}, results, strategies, ...
    {'Ceq_Damper_NsPm','Beq_Damper_kg','Keq_Damper_NPm'}, ...
    {'c_{eq,d} [N s/m]','b_{eq,d} [kg]','k_{eq,d} [N/m]'}, ...
    '可控减振器端口 FDEI');
figures{2} = makeFigure('Total suspension FDEI', visible);
drawMetricFigure(figures{2}, results, strategies, ...
    {'Ceq_Total_NsPm','Beq_Total_kg','Keq_Total_NPm'}, ...
    {'c_{eq,total} [N s/m]','b_{eq,total} [kg]','k_{eq,total} [N/m]'}, ...
    '总悬架 FDEI（含并联弹簧）');

if saveFigures
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end
    exportOne(figures{1}, fullfile(outputDir, '01_damper_port_FDEI.png'));
    exportOne(figures{2}, fullfile(outputDir, '02_total_suspension_FDEI.png'));
end
end

function drawMetricFigure(fig, results, strategies, fields, labels, titleText)
layout = tiledlayout(fig, 3, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
for metricIndex = 1:3
    ax = nexttile(layout);
    hold(ax, 'on');
    for strategyIndex = 1:numel(strategies)
        keep = string(results.Strategy) == strategies(strategyIndex) & ...
            isfinite(results.Frequency_Hz) & isfinite(results.(fields{metricIndex}));
        if any(keep)
            frequency = results.Frequency_Hz(keep);
            metric = results.(fields{metricIndex})(keep);
            [frequency, order] = sort(frequency);
            metric = metric(order);
            semilogx(ax, frequency, metric, '-o', ...
                'DisplayName', char(strategies(strategyIndex)));
        end
    end
    ax.XScale = 'log';
    ylabel(ax, labels{metricIndex});
    grid(ax, 'on');
    if metricIndex == 1
        title(ax, titleText);
    end
    if metricIndex == 3
        xlabel(ax, 'Frequency [Hz]');
    end
    if metricIndex == 1 && numel(strategies) > 0
        legend(ax, 'Location', 'best');
    end
end
end

function fig = makeFigure(name, visible)
fig = figure('Name', name, 'Color', 'w', 'Visible', visible);
end

function exportOne(fig, fileName)
try
    exportgraphics(fig, fileName, 'Resolution', 180);
catch
    saveas(fig, fileName);
end
end

function value = getOption(cfg, fieldName, fallback)
if isstruct(cfg) && isfield(cfg, fieldName)
    value = cfg.(fieldName);
else
    value = fallback;
end
end

function tf = istableSafe(value)
tf = false;
try
    tf = istable(value);
catch
end
end
