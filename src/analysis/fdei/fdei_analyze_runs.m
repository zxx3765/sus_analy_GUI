function [results, summary, context] = fdei_analyze_runs(runs, cfg)
%FDEI_ANALYZE_RUNS Compute FDEI results and strategy summaries.
%   [RESULTS,SUMMARY,CONTEXT] = FDEI_ANALYZE_RUNS(RUNS,CFG) analyzes the
%   compatible runs contract without requiring a Simulink model or the
%   external reference directory.

if nargin < 2 || isempty(cfg)
    cfg = fdei_default_config('analysis');
end
validateAnalysisConfig(cfg, runs);
rows = repmat(emptyResultRow(), numel(runs), 1);
c0 = 0.5*(cfg.cMax + cfg.cMin);
cDelta = 0.5*(cfg.cMax - cfg.cMin);
for index = 1:numel(runs)
    rows(index) = analyzeOneRun(runs(index), index, cfg, c0, cDelta);
end
results = struct2table(rows);
results = sortrows(results, {'StrategyOrder','Frequency_Hz'});
summary = buildSummary(results);
context = struct('cfg', cfg, 'runCount', numel(runs));
end

function validateAnalysisConfig(cfg, runs)
required = {'cMin','cMax','ks','alpha','vdToCanonicalSign', ...
    'forceToCanonicalSign','forceInputMode','forceBaselineDamping', ...
    'switchPolarity','zeroSwitchState','lastNCycles','harmonicOrder', ...
    'minSamplesPerCycle','smallSignalRelTol','boundaryRelTol'};
for index = 1:numel(required)
    if ~isfield(cfg, required{index})
        error('fdei_analyze_runs:MissingConfig', ...
            '缺少分析配置字段 %s。', required{index});
    end
end
finiteScalar(cfg.cMin, 'cMin');
finiteScalar(cfg.cMax, 'cMax');
finiteScalar(cfg.ks, 'ks');
finiteScalar(cfg.alpha, 'alpha');
if cfg.cMin < 0 || cfg.cMax <= cfg.cMin
    error('fdei_analyze_runs:InvalidDampingRange', ...
        '必须满足 0 <= cMin < cMax。');
end
if cfg.ks <= 0 || cfg.alpha <= 0
    error('fdei_analyze_runs:InvalidPhysicalParameter', ...
        'ks 和 alpha 必须为正数。');
end
if ~ismember(cfg.vdToCanonicalSign, [-1,1]) || ...
        ~ismember(cfg.forceToCanonicalSign, [-1,1])
    error('fdei_analyze_runs:InvalidSign', ...
        '信号符号只能为 +1 或 -1。');
end
if ~ismember(lower(strtrim(char(string(cfg.forceInputMode)))), ...
        {'total','control_increment'})
    error('fdei_analyze_runs:InvalidForceMode', ...
        'forceInputMode 只能是 total 或 control_increment。');
end
finiteScalar(cfg.forceBaselineDamping, 'forceBaselineDamping');
if cfg.forceBaselineDamping < 0
    error('fdei_analyze_runs:InvalidBaseline', ...
        'forceBaselineDamping 不能为负数。');
end
if ~ismember(cfg.switchPolarity, [-1,1]) || ~ismember(cfg.zeroSwitchState, [-1,1])
    error('fdei_analyze_runs:InvalidSwitchSign', ...
        'switchPolarity 和 zeroSwitchState 只能为 +1 或 -1。');
end
if ~(isnumeric(cfg.lastNCycles) && isscalar(cfg.lastNCycles) && ...
        isfinite(cfg.lastNCycles) && cfg.lastNCycles > 0)
    error('fdei_analyze_runs:InvalidWindow', 'lastNCycles 必须为正标量。');
end
if ~(isnumeric(cfg.harmonicOrder) && isscalar(cfg.harmonicOrder) && ...
        isfinite(cfg.harmonicOrder) && cfg.harmonicOrder >= 1)
    error('fdei_analyze_runs:InvalidHarmonicOrder', ...
        'harmonicOrder 必须是不小于 1 的标量。');
end
if cfg.minSamplesPerCycle <= 0 || cfg.smallSignalRelTol <= 0 || ...
        cfg.boundaryRelTol <= 0
    error('fdei_analyze_runs:InvalidTolerance', ...
        'minSamplesPerCycle 和容差必须为正数。');
end
if isempty(runs) || ~isstruct(runs)
    error('fdei_analyze_runs:InvalidRuns', 'runs 必须是非空结构体数组。');
end
end

function finiteScalar(value, name)
if ~(isnumeric(value) && isscalar(value) && isfinite(value))
    error('fdei_analyze_runs:InvalidScalar', '%s 必须是有限标量。', name);
end
end

function row = analyzeOneRun(runData, runIndex, cfg, c0, cDelta)
strategy = string(fdei_canonical_algorithm_name(runField(runData, 'strategy')));
definition = algorithmDefinition(strategy);
strategyOrder = strategyOrderOf(strategy);
fHz = runField(runData, 'fHz');
if ~(isnumeric(fHz) && isscalar(fHz) && isfinite(fHz) && fHz > 0)
    error('runs(%d).fHz 必须是正的有限标量。', runIndex);
end
sig = prepareSignals(runData, runIndex, cfg);
omega = 2*pi*fHz;
[idx, tStart, tEnd] = selectAnalysisWindow(sig.t, fHz, cfg);
sig = trimSignals(sig, idx);
t = sig.t;
nSamples = numel(t);
duration = t(end)-t(1);
samplesPerCycle = nSamples/max(duration*fHz, eps);
if samplesPerCycle < cfg.minSamplesPerCycle
    warning('fdei_analyze_runs:SparseSamples', ...
        'runs(%d), %.4g Hz：每周期约 %.1f 个样本。', ...
        runIndex, fHz, samplesPerCycle);
end

eta = sig.as + cfg.alpha*sig.vs;
q = selectQ(definition.QMode, sig, cfg.alpha);
naturalUnit = string(definition.NaturalUnit);
[Vd1, vdTHD] = harmonicPhasorAndTHD(t, sig.vd, omega, cfg.harmonicOrder);
[Fd1, fdTHD] = harmonicPhasorAndTHD(t, sig.Fd, omega, cfg.harmonicOrder);
[Vs1, ~] = harmonicPhasorAndTHD(t, sig.vs, omega, cfg.harmonicOrder);
[As1, ~] = harmonicPhasorAndTHD(t, sig.as, omega, cfg.harmonicOrder);
[Q1, ~] = harmonicPhasorAndTHD(t, q, omega, cfg.harmonicOrder);
[Eta1, ~] = harmonicPhasorAndTHD(t, eta, omega, cfg.harmonicOrder);
requirePhasor(Vd1, 'v_d', runIndex, fHz);

Zident = Fd1/Vd1;
Ztotal = cfg.ks/(1i*omega) + Zident;
[cEqDamper, bEqDamper, kEqDamper] = impedanceToFdei(Zident, omega);
[cEqTotal, bEqTotal, kEqTotal] = impedanceToFdei(Ztotal, omega);
identityErr = 100*abs(kEqTotal + omega^2*bEqTotal)/ ...
    max([abs(kEqTotal), abs(omega^2*bEqTotal), 1]);

if strcmpi(definition.QMode, 'passive')
    phi = NaN;
    Dphi = NaN;
    Xphi = NaN;
    Zclosed = c0;
    cIdeal = c0*ones(size(sig.vd));
else
    phi = wrapToPi(angle(Q1/Vd1));
    [Dphi, Xphi] = describingFunction(phi);
    Zclosed = c0 + cfg.switchPolarity*cDelta*(Dphi + 1i*Xphi);
    switchArg = cfg.switchPolarity*q.*sig.vd;
    cIdeal = c0 + cDelta*binarySwitchSign(switchArg, cfg.zeroSwitchState);
end
Fideal = cIdeal.*sig.vd;
Fideal1 = harmonicPhasor(t, Fideal, omega, cfg.harmonicOrder);
ZidealNum = Fideal1/Vd1;

Fnl = sig.Fd - c0*sig.vd;
[naturalCoeff, naturalFitR2, naturalFitRelRMS] = ...
    weightedThroughOriginFit(t, q, Fnl);
if abs(Vs1) > phasorTol(Vs1)
    Fnl1 = harmonicPhasor(t, Fnl, omega, cfg.harmonicOrder);
    ZbodyActual = Fnl1/Vs1;
    switch lower(definition.QMode)
        case 'passive'
            ZbodyIdeal = 0;
        case 'vs'
            ZbodyIdeal = naturalCoeff;
        case 'as'
            ZbodyIdeal = 1i*omega*naturalCoeff;
        otherwise
            ZbodyIdeal = naturalCoeff*(cfg.alpha + 1i*omega);
    end
    bodyZErr = relativeComplexError(ZbodyActual, ZbodyIdeal);
else
    ZbodyActual = complex(NaN,NaN);
    ZbodyIdeal = complex(NaN,NaN);
    bodyZErr = NaN;
end
if abs(Vs1) > phasorTol(Vs1)
    kinAsVsErr = 100*abs(As1/(1i*omega*Vs1)-1);
    kinEtaVsErr = 100*abs(Eta1/((cfg.alpha+1i*omega)*Vs1)-1);
else
    kinAsVsErr = NaN;
    kinEtaVsErr = NaN;
end
[switchMismatch, cCmdNRMSE] = compareDamping(t, sig.cCmd, sig.Fd, ...
    sig.vd, q, cIdeal, c0, cfg);
shaddMismatch = NaN;
if definition.RunSHADDDiagnostic
    shaddMismatch = compareSHADD(sig.vs, sig.as, sig.vd, cfg);
end
power = sig.Fd.*sig.vd;
meanPower = weightedMean(t, power);
pScale = max(abs(power));
negativePowerPct = 100*weightedFraction(t, power < ...
    -cfg.smallSignalRelTol*max(pScale,1));
[accelGain, tireGain, suspGain] = optionalGains(sig, t, omega, ...
    cfg.harmonicOrder, As1);

row = emptyResultRow();
row.RunIndex = runIndex;
row.Strategy = strategy;
row.StrategyOrder = strategyOrder;
row.Frequency_Hz = fHz;
row.WindowStart_s = tStart;
row.WindowEnd_s = tEnd;
row.Samples = nSamples;
row.SamplesPerCycle = samplesPerCycle;
row.MeanPower_W = meanPower;
row.NegativePower_pct = negativePowerPct;
row.QminusVd_Phase_deg = rad2deg(phi);
row.D_Theory = Dphi;
row.X_Theory = Xphi;
row.Vd1_Amp = abs(Vd1);
row.Fd1_Amp_N = abs(Fd1);
row.Z_Ident_Re_NsPm = real(Zident);
row.Z_Ident_Im_NsPm = imag(Zident);
row.Ceq_Damper_NsPm = cEqDamper;
row.Beq_Damper_kg = bEqDamper;
row.Keq_Damper_NPm = kEqDamper;
row.Ceq_Total_NsPm = cEqTotal;
row.Beq_Total_kg = bEqTotal;
row.Keq_Total_NPm = kEqTotal;
row.FDEI_Identity_Error_pct = identityErr;
row.Z_Closed_Re_NsPm = real(Zclosed);
row.Z_Closed_Im_NsPm = imag(Zclosed);
row.Z_IdealNum_Re_NsPm = real(ZidealNum);
row.Z_IdealNum_Im_NsPm = imag(ZidealNum);
row.Err_Actual_vs_IdealNum_pct = relativeComplexError(Zident,ZidealNum);
row.Err_Closed_vs_IdealNum_pct = relativeComplexError(Zclosed,ZidealNum);
row.Err_Actual_vs_Closed_pct = relativeComplexError(Zident,Zclosed);
row.NaturalCoeff = naturalCoeff;
row.NaturalCoeffUnit = naturalUnit;
row.NaturalFit_R2 = naturalFitR2;
row.NaturalFit_RelRMS_pct = 100*naturalFitRelRMS;
row.SwitchMismatch_pct = switchMismatch;
row.Ccmd_NRMSE_pct = cCmdNRMSE;
row.SHADD_OrigReducedMismatch_pct = shaddMismatch;
row.Vd_THD_pct = 100*vdTHD;
row.Fd_THD_pct = 100*fdTHD;
row.Kinematic_AsVs_Error_pct = kinAsVsErr;
row.Kinematic_EtaVs_Error_pct = kinEtaVsErr;
row.BodyZ_Actual_Re_NsPm = real(ZbodyActual);
row.BodyZ_Actual_Im_NsPm = imag(ZbodyActual);
row.BodyZ_Ideal_Re_NsPm = real(ZbodyIdeal);
row.BodyZ_Ideal_Im_NsPm = imag(ZbodyIdeal);
row.BodyZ_Error_pct = bodyZErr;
row.AccelGain_As_over_Xr = accelGain;
row.TireDefGain = tireGain;
row.SuspDefGain = suspGain;
end

function value = runField(runData, fieldName)
if ~isfield(runData, fieldName)
    error('fdei_analyze_runs:MissingRunField', 'runs 缺少字段 %s。', fieldName);
end
value = runData.(fieldName);
end

function q = selectQ(qMode, sig, alpha)
switch lower(qMode)
    case 'passive'
        q = zeros(size(sig.vs));
    case 'vs'
        q = sig.vs;
    case 'as'
        q = sig.as;
    case 'eta'
        q = sig.as + alpha*sig.vs;
    otherwise
        error('fdei_analyze_runs:UnsupportedQMode', '未实现 QMode=%s。', qMode);
end
end

function sig = prepareSignals(runData, runIndex, cfg)
sig.t = vectorize(runField(runData, 't'), sprintf('runs(%d).t', runIndex));
sig.vs = vectorize(runField(runData, 'vs'), sprintf('runs(%d).vs', runIndex));
sig.as = vectorize(runField(runData, 'as'), sprintf('runs(%d).as', runIndex));
vd = getOptional(runData, 'vd');
vu = getOptional(runData, 'vu');
if isempty(vd)
    if isempty(vu)
        error('runs(%d) 必须提供 vd，或同时提供 vu。', runIndex);
    end
    vu = vectorize(vu, sprintf('runs(%d).vu', runIndex));
    checkLength(vu, sig.t, 'vu');
    vd = sig.vs-vu;
else
    vd = vectorize(vd, sprintf('runs(%d).vd', runIndex));
end
sig.vd = cfg.vdToCanonicalSign*vd;
sig.cCmd = optionalVector(getOptional(runData, 'cCmd'), 'cCmd');
fd = getOptional(runData, 'Fd');
if isempty(fd)
    if isempty(sig.cCmd)
        error('runs(%d) 必须提供 Fd，或提供 cCmd。', runIndex);
    end
    sig.Fd = sig.cCmd.*sig.vd;
else
    fd = vectorize(fd, sprintf('runs(%d).Fd', runIndex));
    fd = cfg.forceToCanonicalSign*fd;
    if strcmpi(strtrim(char(string(cfg.forceInputMode))), 'control_increment')
        sig.Fd = cfg.forceBaselineDamping*sig.vd+fd;
    else
        sig.Fd = fd;
    end
end
optionalNames = {'xr','xu','tireDef','suspDef'};
for index = 1:numel(optionalNames)
    fieldName = optionalNames{index};
    sig.(fieldName) = optionalVector(getOptional(runData, fieldName), fieldName);
end
fields = {'vs','as','vd','Fd','cCmd','xr','xu','tireDef','suspDef'};
for index = 1:numel(fields)
    fieldName = fields{index};
    if ~isempty(sig.(fieldName))
        checkLength(sig.(fieldName), sig.t, fieldName);
    end
end
[~, order] = sort(sig.t);
sig = reorderSignals(sig, order);
[~, uniqueIndex] = unique(sig.t, 'stable');
sig = reorderSignals(sig, uniqueIndex);
finiteMask = isfinite(sig.t) & isfinite(sig.vs) & isfinite(sig.as) & ...
    isfinite(sig.vd) & isfinite(sig.Fd);
sig = reorderSignals(sig, finiteMask);
if numel(sig.t) < 20
    error('runs(%d) 可用样本少于 20。', runIndex);
end
if any(diff(sig.t) <= 0)
    error('runs(%d) 时间向量必须严格递增。', runIndex);
end
end

function value = getOptional(runData, fieldName)
if isfield(runData, fieldName)
    value = runData.(fieldName);
else
    value = [];
end
end

function value = vectorize(value, name)
if isa(value, 'timeseries')
    value = value.Data;
end
if isempty(value)
    error('%s 为空。', name);
end
value = squeeze(value);
if ~isvector(value)
    error('%s 必须是一维信号。', name);
end
value = double(value(:));
end

function value = optionalVector(value, name)
if isempty(value)
    value = [];
else
    value = vectorize(value, name);
end
end

function checkLength(value, t, name)
if numel(value) ~= numel(t)
    error('%s 长度为 %d，但时间向量长度为 %d。', ...
        name, numel(value), numel(t));
end
end

function sig = reorderSignals(sig, index)
fields = fieldnames(sig);
nOld = numel(sig.t);
for fieldIndex = 1:numel(fields)
    fieldName = fields{fieldIndex};
    value = sig.(fieldName);
    if ~isempty(value) && isvector(value) && numel(value) == nOld
        sig.(fieldName) = value(index);
    end
end
end

function sig = trimSignals(sig, index)
%TRIMSIGNALS Keep every aligned signal inside the selected analysis window.
fields = fieldnames(sig);
nOld = numel(sig.t);
for fieldIndex = 1:numel(fields)
    fieldName = fields{fieldIndex};
    value = sig.(fieldName);
    if ~isempty(value) && isvector(value) && numel(value) == nOld
        sig.(fieldName) = value(index);
    end
end
end

function [index, tStart, tEnd] = selectAnalysisWindow(t, fHz, cfg)
tEnd = min(t(end), cfg.analysisEndTime);
if isfinite(cfg.analysisStartTime)
    tStart = max(t(1), cfg.analysisStartTime);
else
    tStart = max(t(1), tEnd-cfg.lastNCycles/fHz);
end
index = t >= tStart & t <= tEnd;
if nnz(index) < 20
    error('fdei_analyze_runs:InsufficientWindow', ...
        '稳态分析窗口内样本少于 20。');
end
if (tEnd-tStart)*fHz < 2
    warning('fdei_analyze_runs:ShortWindow', ...
        '分析窗口只有约 %.2f 个周期。', (tEnd-tStart)*fHz);
end
end

function definition = algorithmDefinition(strategy)
registry = fdei_algorithm_registry();
index = find(strcmp({registry.Name}, char(strategy)), 1);
if isempty(index)
    error('fdei_analyze_runs:UnknownAlgorithm', ...
        '未找到算法 %s 的注册定义。', strategy);
end
definition = registry(index);
end

function order = strategyOrderOf(strategy)
registry = fdei_algorithm_registry();
order = find(strcmp({registry.Name}, char(strategy)), 1);
if isempty(order)
    order = 99;
end
end

function [Y1, thd] = harmonicPhasorAndTHD(t, y, omega, maxOrder)
Y = harmonicPhasors(t, y, omega, maxOrder);
Y1 = Y(1);
if abs(Y1) <= phasorTol(Y1)
    thd = NaN;
else
    thd = sqrt(sum(abs(Y(2:end)).^2))/abs(Y1);
end
end

function Y1 = harmonicPhasor(t, y, omega, maxOrder)
Y = harmonicPhasors(t, y, omega, maxOrder);
Y1 = Y(1);
end

function Y = harmonicPhasors(t, y, omega, maxOrder)
t = t(:);
y = y(:);
maxOrder = max(1, floor(maxOrder));
tau = t-t(1);
A = ones(numel(t), 1+2*maxOrder);
for harmonic = 1:maxOrder
    A(:,2*harmonic) = cos(harmonic*omega*tau);
    A(:,2*harmonic+1) = sin(harmonic*omega*tau);
end
weights = trapezoidalWeights(t);
scale = sqrt(weights);
Aw = bsxfun(@times, A, scale);
beta = Aw\(y.*scale);
Y = complex(zeros(maxOrder,1));
for harmonic = 1:maxOrder
    Y(harmonic) = beta(2*harmonic)-1i*beta(2*harmonic+1);
end
end

function requirePhasor(value, name, runIndex, fHz)
if ~(isfinite(real(value)) && isfinite(imag(value))) || ...
        abs(value) <= phasorTol(value)
    error('runs(%d), %.4g Hz：%s 的基波幅值过小。', runIndex, fHz, name);
end
end

function tol = phasorTol(value)
tol = max(1e-12, 100*eps(max(abs(value),1)));
end

function [cEq, bEq, kEq] = impedanceToFdei(z, omega)
cEq = real(z);
bEq = imag(z)/omega;
kEq = -omega*imag(z);
end

function [D, X] = describingFunction(phi)
phi = wrapToPi(phi);
a = abs(phi);
D = 1-2*a/pi+sin(2*a)/pi;
X = sign(phi)*(1-cos(2*phi))/pi;
end

function value = wrapToPi(value)
value = mod(value+pi, 2*pi)-pi;
end

function value = relativeComplexError(z, reference)
if ~(isfinite(real(z)) && isfinite(imag(z)) && ...
        isfinite(real(reference)) && isfinite(imag(reference)))
    value = NaN;
else
    value = 100*abs(z-reference)/max(abs(reference), 1e-12);
end
end

function [beta, r2, relativeRms] = weightedThroughOriginFit(t, x, y)
weights = trapezoidalWeights(t);
denominator = sum(weights.*x.^2);
if denominator <= eps
    beta = NaN;
    r2 = NaN;
    relativeRms = NaN;
    return;
end
beta = sum(weights.*x.*y)/denominator;
yHat = beta*x;
residual = y-yHat;
yMean = sum(weights.*y)/sum(weights);
sse = sum(weights.*residual.^2);
sst = sum(weights.*(y-yMean).^2);
if sst > eps
    r2 = 1-sse/sst;
else
    r2 = NaN;
end
relativeRms = sqrt(sse/max(sum(weights.*y.^2), eps));
end

function state = binarySwitchSign(value, zeroState)
state = zeroState*ones(size(value));
state(value > 0) = 1;
state(value < 0) = -1;
end

function [mismatchPct, nrmsePct] = compareDamping(t, cCmd, fd, vd, q, cIdeal, c0, cfg)
vdScale = max(abs(vd));
qScale = max(abs(q));
valid = abs(vd) > cfg.smallSignalRelTol*max(vdScale,eps) & ...
    abs(q) > cfg.smallSignalRelTol*max(qScale,eps);
if ~any(valid)
    mismatchPct = NaN;
    nrmsePct = NaN;
    return;
end
if isempty(cCmd)
    cActual = NaN(size(vd));
    cActual(valid) = fd(valid)./vd(valid);
else
    cActual = cCmd;
end
valid = valid & isfinite(cActual);
if ~any(valid)
    mismatchPct = NaN;
    nrmsePct = NaN;
    return;
end
actualHigh = cActual >= c0;
idealHigh = cIdeal >= c0;
mismatchPct = 100*weightedFraction(t, valid & (actualHigh ~= idealHigh), valid);
err = cActual-cIdeal;
weights = trapezoidalWeights(t);
weights(~valid) = 0;
nrmsePct = 100*sqrt(sum(weights.*err.^2)/max(sum(weights),eps))/ ...
    max(cfg.cMax-cfg.cMin,eps);
end

function mismatchPct = compareSHADD(vs, as, vd, cfg)
addDominant = abs(as) > cfg.alpha*abs(vs);
qOriginal = vs;
qOriginal(addDominant) = as(addDominant);
argOriginal = cfg.switchPolarity*qOriginal.*vd;
argReduced = cfg.switchPolarity*(as+cfg.alpha*vs).*vd;
scaleBoundary = max([max(abs(as)), cfg.alpha*max(abs(vs)), eps]);
boundary = abs(abs(as)-cfg.alpha*abs(vs)) <= ...
    cfg.boundaryRelTol*scaleBoundary;
scaleArg = max([max(abs(argOriginal)), max(abs(argReduced)), eps]);
nonzero = abs(argOriginal) > cfg.smallSignalRelTol*scaleArg & ...
    abs(argReduced) > cfg.smallSignalRelTol*scaleArg;
valid = ~boundary & nonzero;
if any(valid)
    mismatchPct = 100*mean(sign(argOriginal(valid)) ~= sign(argReduced(valid)));
else
    mismatchPct = NaN;
end
end

function [accelGain, tireGain, suspGain] = optionalGains(sig, t, omega, order, As1)
accelGain = NaN;
tireGain = NaN;
suspGain = NaN;
if isempty(sig.xr)
    return;
end
Xr1 = harmonicPhasor(t, sig.xr, omega, order);
if abs(Xr1) <= phasorTol(Xr1)
    return;
end
accelGain = abs(As1/Xr1);
if ~isempty(sig.tireDef)
    tire = sig.tireDef;
elseif ~isempty(sig.xu)
    tire = sig.xu-sig.xr;
else
    tire = [];
end
if ~isempty(tire)
    tireGain = abs(harmonicPhasor(t, tire, omega, order)/Xr1);
end
if ~isempty(sig.suspDef)
    suspGain = abs(harmonicPhasor(t, sig.suspDef, omega, order)/Xr1);
end
end

function value = weightedMean(t, x)
weights = trapezoidalWeights(t);
value = sum(weights.*x)/sum(weights);
end

function value = weightedFraction(t, mask, validMask)
if nargin < 3
    validMask = true(size(mask));
end
weights = trapezoidalWeights(t);
weights(~validMask) = 0;
denominator = sum(weights);
if denominator <= eps
    value = NaN;
else
    value = sum(weights.*double(mask))/denominator;
end
end

function weights = trapezoidalWeights(t)
t = t(:);
n = numel(t);
if n < 2
    weights = ones(size(t));
    return;
end
dt = diff(t);
weights = zeros(n,1);
weights(1) = dt(1)/2;
weights(end) = dt(end)/2;
if n > 2
    weights(2:end-1) = (dt(1:end-1)+dt(2:end))/2;
end
weights = max(weights, eps);
end

function summary = buildSummary(results)
registry = fdei_algorithm_registry();
out = repmat(struct('Strategy', "", 'Runs', 0, 'FreqMin_Hz', NaN, ...
    'FreqMax_Hz', NaN, 'Median_ActualIdealErr_pct', NaN, ...
    'Median_ClosedIdealErr_pct', NaN, 'Median_SwitchMismatch_pct', NaN, ...
    'Median_NaturalFit_R2', NaN, 'Median_ForceTHD_pct', NaN, ...
    'Max_SHADD_OrigReducedMismatch_pct', NaN), 0, 1);
for index = 1:numel(registry)
    strategy = string(registry(index).Name);
    keep = results.Strategy == strategy;
    if ~any(keep)
        continue;
    end
    row = outTemplate();
    row.Strategy = strategy;
    row.Runs = nnz(keep);
    row.FreqMin_Hz = min(results.Frequency_Hz(keep));
    row.FreqMax_Hz = max(results.Frequency_Hz(keep));
    row.Median_ActualIdealErr_pct = finiteMedian(results.Err_Actual_vs_IdealNum_pct(keep));
    row.Median_ClosedIdealErr_pct = finiteMedian(results.Err_Closed_vs_IdealNum_pct(keep));
    row.Median_SwitchMismatch_pct = finiteMedian(results.SwitchMismatch_pct(keep));
    row.Median_NaturalFit_R2 = finiteMedian(results.NaturalFit_R2(keep));
    row.Median_ForceTHD_pct = finiteMedian(results.Fd_THD_pct(keep));
    row.Max_SHADD_OrigReducedMismatch_pct = finiteMax( ...
        results.SHADD_OrigReducedMismatch_pct(keep));
    out(end+1,1) = row; %#ok<AGROW>
end
if isempty(out)
    summary = table();
else
    summary = struct2table(out);
end
end

function row = outTemplate()
row = struct('Strategy', "", 'Runs', 0, 'FreqMin_Hz', NaN, ...
    'FreqMax_Hz', NaN, 'Median_ActualIdealErr_pct', NaN, ...
    'Median_ClosedIdealErr_pct', NaN, 'Median_SwitchMismatch_pct', NaN, ...
    'Median_NaturalFit_R2', NaN, 'Median_ForceTHD_pct', NaN, ...
    'Max_SHADD_OrigReducedMismatch_pct', NaN);
end

function value = finiteMedian(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = median(values);
end
end

function value = finiteMax(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = max(values);
end
end

function row = emptyResultRow()
row = struct('RunIndex', NaN, 'Strategy', "", 'StrategyOrder', NaN, ...
    'Frequency_Hz', NaN, 'WindowStart_s', NaN, 'WindowEnd_s', NaN, ...
    'Samples', NaN, 'SamplesPerCycle', NaN, 'MeanPower_W', NaN, ...
    'NegativePower_pct', NaN, 'QminusVd_Phase_deg', NaN, 'D_Theory', NaN, ...
    'X_Theory', NaN, 'Vd1_Amp', NaN, 'Fd1_Amp_N', NaN, ...
    'Z_Ident_Re_NsPm', NaN, 'Z_Ident_Im_NsPm', NaN, ...
    'Ceq_Damper_NsPm', NaN, 'Beq_Damper_kg', NaN, ...
    'Keq_Damper_NPm', NaN, 'Ceq_Total_NsPm', NaN, ...
    'Beq_Total_kg', NaN, 'Keq_Total_NPm', NaN, ...
    'FDEI_Identity_Error_pct', NaN, 'Z_Closed_Re_NsPm', NaN, ...
    'Z_Closed_Im_NsPm', NaN, 'Z_IdealNum_Re_NsPm', NaN, ...
    'Z_IdealNum_Im_NsPm', NaN, 'Err_Actual_vs_IdealNum_pct', NaN, ...
    'Err_Closed_vs_IdealNum_pct', NaN, 'Err_Actual_vs_Closed_pct', NaN, ...
    'NaturalCoeff', NaN, 'NaturalCoeffUnit', "", 'NaturalFit_R2', NaN, ...
    'NaturalFit_RelRMS_pct', NaN, 'SwitchMismatch_pct', NaN, ...
    'Ccmd_NRMSE_pct', NaN, 'SHADD_OrigReducedMismatch_pct', NaN, ...
    'Vd_THD_pct', NaN, 'Fd_THD_pct', NaN, ...
    'Kinematic_AsVs_Error_pct', NaN, 'Kinematic_EtaVs_Error_pct', NaN, ...
    'BodyZ_Actual_Re_NsPm', NaN, 'BodyZ_Actual_Im_NsPm', NaN, ...
    'BodyZ_Ideal_Re_NsPm', NaN, 'BodyZ_Ideal_Im_NsPm', NaN, ...
    'BodyZ_Error_pct', NaN, 'AccelGain_As_over_Xr', NaN, ...
    'TireDefGain', NaN, 'SuspDefGain', NaN);
end
