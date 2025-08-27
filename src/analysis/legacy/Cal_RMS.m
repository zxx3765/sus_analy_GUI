function [RMS_AV,RMS_AV_value] = Cal_RMS(H_sym,H_sym_value)
    % 计算均方根值
    syms s2 s
    [num_H, den_H] = numden(H_sym);
    G_s = collect(num_H/s * subs(num_H/s,s,-s),s);
    
    [b_set,terms_b] = coeffs(subs(G_s,s^2,s2), s2,'All');
    [a_set,terms_a] = coeffs(den_H, s,'All');
    % [a_set,terms_a] = coeffs(den_H, s);
    % b_set = fliplr(b_set);
    % a_set = fliplr(a_set);
    % n_rms = degree(den_H, s);
    degrees_a = arrayfun(@(t) feval(symengine, 'degree', t, s), terms_a);  % 获取每一项的次数
    max_degree_a = max(degrees_a);  % 找到最高次幂
    degrees_b = arrayfun(@(t) feval(symengine, 'degree', t, s2), terms_b);  % 获取每一项的次数
    max_degree_b = max(degrees_b);  % 找到最高次幂
    n_rms = double(max_degree_a);
    n_rms_b = double(max_degree_b);
    delta_mtrix = sym(zeros(n_rms,n_rms)); % 推导均方根值理论代数表达式时用
    % delta_mtrix = zeros(n_rms,n_rms); %推导均方根值实际数值时用
    b_set = [zeros(1,n_rms-n_rms_b-1) b_set];
    for i = 1 : n_rms
        for j = 1:n_rms
            if  or((2*i - j + 1) < 1,(2*i - j + 1) > n_rms+1)
            else
                delta_mtrix(i,j) = a_set(2*i-j+1)*(-1)^j;
            end
        end
    end
    delta_mtrix_1 = delta_mtrix;
    delta_mtrix_1(:,1) = b_set;
    syms A V
    RMS_H_sym = simplify(2*pi*A*V*(-1)^n_rms/(2*a_set(1))*det(delta_mtrix_1)/det(delta_mtrix));
    RMS_AV = coeffs(RMS_H_sym,[A,V,pi]);
    % collect(RMS_AV,[pi,k1])
    
    % 计算均方根值数值
    [num_H, den_H] = numden(H_sym_value);
    G_s = collect(num_H/s * subs(num_H/s,s,-s),s);
    syms s2
    [b_set,terms_b] = coeffs(subs(G_s,s^2,s2), s2,'All');
    [a_set,terms_a] = coeffs(den_H, s,'All');
    % [a_set,terms_a] = coeffs(den_H, s);
    % b_set = fliplr(b_set);
    % a_set = fliplr(a_set);
    % n_rms = degree(den_H, s);
    degrees_a = arrayfun(@(t) feval(symengine, 'degree', t, s), terms_a);  % 获取每一项的次数
    max_degree_a = max(degrees_a);  % 找到最高次幂
    degrees_b = arrayfun(@(t) feval(symengine, 'degree', t, s2), terms_b);  % 获取每一项的次数
    max_degree_b = max(degrees_b);  % 找到最高次幂
    n_rms = double(max_degree_a);
    n_rms_b = double(max_degree_b);
    delta_mtrix = sym(zeros(n_rms,n_rms)); % 推导均方根值理论代数表达式时用
    % delta_mtrix = zeros(n_rms,n_rms); %推导均方根值实际数值时用
    b_set = [zeros(1,n_rms-n_rms_b-1) b_set];
    for i = 1 : n_rms
        for j = 1:n_rms
            if  or((2*i - j + 1) < 1,(2*i - j + 1) > n_rms+1)
            else
                delta_mtrix(i,j) = a_set(2*i-j+1)*(-1)^j;
            end
        end
    end
    delta_mtrix_1 = delta_mtrix;
    delta_mtrix_1(:,1) = b_set;
    syms A V
    RMS_H_value = simplify(2*pi*A*V*(-1)^n_rms/(2*a_set(1))*det(delta_mtrix_1)/det(delta_mtrix));
    RMS_AV_value = coeffs(RMS_H_value,[A,V,pi]);
    % double(RMS_AV_value)
end
