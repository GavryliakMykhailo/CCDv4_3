% =========================================================================
% Назва файлу: CCD_v4_Plus1point3.m (Оновлено для графіків 3x3)
% Опис: Пакетна обробка поляризаційних даних з розрахунком як КЛАСИЧНИХ 
%       (одноточкових), так і УЗАГАЛЬНЕНИХ (контрастних) параметрів.
%       Генерує об'єднані картинки 3x3 (Картинка, Усереднення, АКФ).
% =========================================================================

clc; close all;
disp('Початок обробки: CCD_v4_Combined...');

% 1. Налаштування шляхів збереження
base_path ='D:\MyDoc\Programming\mathematik\MyProg\UshenkoOG\2025\temp'; % Можете змінити на свій шлях
main_folder_name = 'Test10_08';

% 2. Визначення діапазонів фаз для обробки
phase_ranges = [
    0, 2*pi, "0_2pi"
];

% Стани поляризації
states = ["0", "90", "45", "135", "prav", "liv"];

% 3. Основний цикл обробки
for p_idx = 1:size(phase_ranges, 1)
    phase_min = double(phase_ranges(p_idx, 1));
    phase_max = double(phase_ranges(p_idx, 2));
    folder_name = phase_ranges(p_idx, 3);
    
    out_dir = fullfile(base_path, main_folder_name, folder_name);
    if ~exist(out_dir, 'dir')
        mkdir(out_dir);
    end
    
    disp(['Обробка діапазону: ', char(folder_name)]);
    
    % Отримуємо координати опорної точки за 0 станом
    ex_0 = evalin('base', 'ex_0');
    ey_0 = evalin('base', 'ey_0');
    amp_total_0 = sqrt(abs(ex_0).^2 + abs(ey_0).^2);
    nearest_coords = find_contrast_nearest_neighbors(amp_total_0, "first_non_nan");
    
    for s_idx = 1:length(states)
        state_name = states(s_idx);
        disp(['  Стан поляризації: ', char(state_name)]);
        
        ex = evalin('base', sprintf('ex_%s', state_name));
        ey = evalin('base', sprintf('ey_%s', state_name));
        
        % Фільтрація за фазою
        [ex_f, ey_f] = filter_by_phase_range(ex, ey, phase_min, phase_max);
        
        % Класичні параметри
        [alpha_cl, beta_cl] = get_classical_polarization(ex_f, ey_f);
        
        % Узагальнені (контрастні) параметри
        [S_gen, alpha_gen, beta_gen] = analyze_polarization_contrast(ex_f, ey_f, false, nearest_coords);
        
        alpha_gen_mod = alpha_gen(:,:,1);
        alpha_gen_arg = alpha_gen(:,:,2);
        
        beta_gen_mod = beta_gen(:,:,1);
        beta_gen_arg = beta_gen(:,:,2);
        
        % -----------------------------------------------------------------
        % Побудова 3x3 для Азимута (Alpha)
        % -----------------------------------------------------------------
        fig_alpha = figure('Visible', 'off', 'Position', [100 100 1500 1000]);
        plot_3x3_column(1, alpha_cl, sprintf('Класичний Азимут\nСтан: %s', state_name));
        plot_3x3_column(2, alpha_gen_mod, sprintf('Контрастний Азимут [Модуль]\nСтан: %s', state_name));
        plot_3x3_column(3, alpha_gen_arg, sprintf('Контрастний Азимут [Аргумент]\nСтан: %s', state_name));
        saveas(fig_alpha, fullfile(out_dir, sprintf('Alpha_Combined_%s.png', state_name)));
        close(fig_alpha);
        
        % -----------------------------------------------------------------
        % Побудова 3x3 для Еліптичності (Beta)
        % -----------------------------------------------------------------
        fig_beta = figure('Visible', 'off', 'Position', [100 100 1500 1000]);
        plot_3x3_column(1, beta_cl, sprintf('Класична Еліптичність\nСтан: %s', state_name));
        plot_3x3_column(2, beta_gen_mod, sprintf('Контрастна Еліптичність [Модуль]\nСтан: %s', state_name));
        plot_3x3_column(3, beta_gen_arg, sprintf('Контрастна Еліптичність [Аргумент]\nСтан: %s', state_name));
        saveas(fig_beta, fullfile(out_dir, sprintf('Beta_Combined_%s.png', state_name)));
        close(fig_beta);
    end
end
disp('Обробка успішно завершена!');

% =========================================================================
% ЛОКАЛЬНІ ФУНКЦІЇ
% =========================================================================

function plot_3x3_column(col, data, base_title)
    % Функція будує 3 графіки у заданому стовпці (col = 1, 2 або 3)
    
    % Відкидаємо NaN для розрахунку статистики та АКФ
    d_valid = real(data(~isnan(data)));
    
    % 1. Розрахунок 4-х статистичних моментів
    if ~isempty(d_valid)
        M1 = mean(d_valid);
        M2 = var(d_valid);
        M3 = skewness(d_valid);
        M4 = kurtosis(d_valid);
    else
        M1=0; M2=0; M3=0; M4=0;
    end
    
    title_str = sprintf('%s\nM1=%.3f, M2=%.3f, M3=%.3f, M4=%.3f', base_title, M1, M2, M3, M4);
    
    % Рядок 1: 2D Картинка
    subplot(3, 3, col);
    imagesc(real(data)); axis image off; colorbar; colormap(gca, 'jet');
    title(title_str);
    
    % Рядок 2: 1D Усереднений графік по вертикалі (mean(data, 1))
    subplot(3, 3, col + 3);
    data_1d_avg = mean(real(data), 1, 'omitnan');
    plot(data_1d_avg, 'LineWidth', 1.5);
    grid on;
    title('Усереднення по вертикалі');
    xlabel('Пікселі (X)');
    ylabel('Значення');
    xlim([1, length(data_1d_avg)]);
    
    % Рядок 3: АКФ від початкової картинки (1D автокореляція)
    subplot(3, 3, col + 6);
    if length(d_valid) > 1
        % Беремо автокореляцію центрованих даних
        [acf, lags] = xcorr(d_valid - M1, 'normalized');
        plot(lags, acf, 'LineWidth', 1);
        grid on;
        title('АКФ початкової картинки');
        xlabel('Lag');
        ylabel('ACF');
        xlim([min(lags), max(lags)]);
    else
        text(0.5, 0.5, 'Недостатньо даних', 'HorizontalAlignment', 'center');
    end
end

function [alpha_cl, beta_cl] = get_classical_polarization(ex, ey)
    % Розрахунок інтенсивностей (кореляція поля з самим собою)
    Wxx = abs(ex).^2;
    Wyy = abs(ey).^2;
    Wxy = conj(ex) .* ey;
    Wyx = conj(ey) .* ex;

    % Класичні параметри Стокса
    S1 = Wxx + Wyy;
    S2 = Wxx - Wyy;
    S3 = Wxy + Wyx;
    S4 = real(1i * (Wyx - Wxy));

    % Азимут та еліптичність
    alpha_cl = 0.5 * atan2(S3, S2);
    beta_cl = 0.5 * asin(S4 ./ S1);
end