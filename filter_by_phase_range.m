function [ex_out, ey_out] = filter_by_phase_range(ex, ey, phase_min, phase_max)
% FILTER_BY_PHASE_RANGE Фільтрує комплексні амплітуди за фазою сумарного сигналу
%
% Вхід:
%   ex, ey       — комплексні матриці (M x N), компоненти поля
%   phase_min    — мінімальне значення фази (в радіанах)
%   phase_max    — максимальне значення фази (в радіанах)
%
% Вихід:
%   ex_out, ey_out — ті ж матриці, але всі значення, де фаза не у вказаному
%                    діапазоні, замінені на NaN

    total_field = ex + 1i * ey;        % Сумарний сигнал
    phase = angle(total_field);       % Фаза в діапазоні (-π, π]
    phase = mod(phase, 2*pi);         % Переводимо у діапазон [0, 2π]

    % Маска фаз, що знаходяться у межах вказаного діапазону
    mask = (phase >= phase_min) & (phase <= phase_max);

    % Ініціалізуємо вихідні масиви як NaN
    ex_out = nan(size(ex));
    ey_out = nan(size(ey));

    % Копіюємо лише допустимі значення
    ex_out(mask) = ex(mask);
    ey_out(mask) = ey(mask);
end
