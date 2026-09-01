function cfg = fdei_load_config(fileName, baseCfg)
%FDEI_LOAD_CONFIG Load and merge an FDEI configuration MAT file.
%   Files exported by FDEI_SAVE_CONFIG use variable fdeiConfig. For
%   compatibility, cfg and batchCfg variables are also accepted.

if nargin < 2 || isempty(baseCfg)
    baseCfg = fdei_default_config();
end
if ~isstruct(baseCfg) || ~isscalar(baseCfg)
    error('fdei_load_config:InvalidBaseConfig', ...
        'baseCfg 必须是标量结构体。');
end
fileName = char(string(fileName));
if exist(fileName, 'file') ~= 2
    error('fdei_load_config:FileNotFound', '找不到配置文件：%s。', fileName);
end

contents = load(fileName, '-mat');
if isfield(contents, 'fdeiConfig')
    imported = contents.fdeiConfig;
elseif isfield(contents, 'cfg')
    imported = contents.cfg;
elseif isfield(contents, 'batchCfg')
    imported = contents.batchCfg;
else
    error('fdei_load_config:MissingConfig', ...
        'MAT 文件中不存在 fdeiConfig、cfg 或 batchCfg。');
end
if ~isstruct(imported) || ~isscalar(imported)
    error('fdei_load_config:InvalidConfig', '导入的配置必须是标量结构体。');
end
cfg = mergeStruct(baseCfg, imported);
end

function merged = mergeStruct(base, overlay)
merged = base;
names = fieldnames(overlay);
for index = 1:numel(names)
    name = names{index};
    if isfield(merged, name) && isstruct(merged.(name)) && ...
            isscalar(merged.(name)) && isstruct(overlay.(name)) && ...
            isscalar(overlay.(name))
        merged.(name) = mergeStruct(merged.(name), overlay.(name));
    else
        merged.(name) = overlay.(name);
    end
end
end
