function is_exp = is_experimental_data(data)
%IS_EXPERIMENTAL_DATA 检测是否为实验数据格式
%
% 输入:
%   data - 待检测的数据结构
%
% 输出:
%   is_exp - 逻辑值,true表示是实验数据格式

    is_exp = false;

    if ~isstruct(data)
        return;
    end

    % 实验数据特征: 包含X和Y字段,且都是结构体数组
    if isfield(data, 'X') && isfield(data, 'Y')
        if ~isempty(data.X) && ~isempty(data.Y)
            % 检查X(1)和Y(1)是否有Data字段
            if isfield(data.X, 'Data') && isfield(data.Y, 'Data')
                is_exp = true;
            end
        end
    end
end
