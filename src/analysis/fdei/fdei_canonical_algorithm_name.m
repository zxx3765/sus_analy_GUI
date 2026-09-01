function name = fdei_canonical_algorithm_name(nameIn)
%FDEI_CANONICAL_ALGORITHM_NAME Convert a display name or alias to a name.

token = normalizeToken(nameIn);
registry = fdei_algorithm_registry();
names = {registry.Name};
for index = 1:numel(registry)
    if strcmp(token, normalizeToken(registry(index).Name))
        name = registry(index).Name;
        return;
    end
    aliases = registry(index).Aliases;
    for aliasIndex = 1:numel(aliases)
        if strcmp(token, normalizeToken(aliases{aliasIndex}))
            name = registry(index).Name;
            return;
        end
    end
end
error('fdei_canonical_algorithm_name:UnknownAlgorithm', ...
    '控制策略分析名称 "%s" 无法识别；已注册算法：%s。', ...
    char(string(nameIn)), strjoin(names, '、'));
end

function token = normalizeToken(value)
token = lower(regexprep(char(string(value)), '[^a-zA-Z0-9]', ''));
end
