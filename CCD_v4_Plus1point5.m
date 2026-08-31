% =========================================================================
% Назва файлу: CCD_v4_Plus1point3.m (Оновлено для графіків 3x3)
% Опис: Пакетна обробка поляризаційних даних з розрахунком як КЛАСИЧНИХ 
%       (одноточкових), так і УЗАГАЛЬНЕНИХ (контрастних) параметрів.
%       Генерує об'єднані картинки 3x3 (Картинка, Усереднення, АКФ).
% =========================================================================

clc; close all;
disp('Початок обробки: CCD_v4_Combined...');

% 1. Налаштування шляхів збереження
base_path ='D:\MyDoc\Programming\mathematik\MyProg\UshenkoOG\Results\Experiment_7_08_26'; % Можете змінити на свій шлях
main_folder_name = 'Мозг_2_OX';
save_data_flag = true; % Змініть на false, щоб вимкнути збереження .mat файлів

% 2. Визначення діапазонів фаз для обробки (10 фазових вибірок від 0-2π до 0-0.25π)
phase_ranges = [
    0, 2*pi - 0*(7*pi/36), "sample_01_2pi";
    0, 2*pi - 1*(7*pi/36), "sample_02_65pi36";
    0, 2*pi - 2*(7*pi/36), "sample_03_29pi18";
    0, 2*pi - 3*(7*pi/36), "sample_04_17pi12";
    0, 2*pi - 4*(7*pi/36), "sample_05_11pi9";
    0, 2*pi - 5*(7*pi/36), "sample_06_37pi36";
    0, 2*pi - 6*(7*pi/36), "sample_07_5pi6";
    0, 2*pi - 7*(7*pi/36), "sample_08_23pi36";
    0, 2*pi - 8*(7*pi/36), "sample_09_4pi9";
    0, 2*pi - 9*(7*pi/36), "sample_10_pi4";
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
    
    % Створення підпапок для збереження .mat файлів та аналізу
    data_dir = fullfile(out_dir, 'data');
    if save_data_flag && ~exist(data_dir, 'dir')
        mkdir(data_dir);
    end
    
    analysis_dir = fullfile(out_dir, 'analysis');
    if ~exist(analysis_dir, 'dir')
        mkdir(analysis_dir);
    end
    
    disp(['Обробка діапазону: ', char(folder_name)]);
    
    % Отримуємо координати опорної точки за 0 станом
    ex_0 = evalin('base', 'ex_0');
    ey_0 = evalin('base', 'ey_0');
    amp_total_0 = sqrt(abs(ex_0).^2 + abs(ey_0).^2);

    nearest_coords = find_contrast_nearest_neighbors(amp_total_0, "row_step", 1);    
%     nearest_coords = find_contrast_nearest_neighbors(amp_total_0, "col_step", 1);
%     nearest_coords = find_contrast_nearest_neighbors(amp_total_0, "diag_down", 1);
   
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
        % Збереження модулів та аргументів азимута і еліптичності
        % -----------------------------------------------------------------
        if save_data_flag
            % Збереження Азимута (Alpha)
            alpha_mod = real(alpha_gen_mod);
            alpha_arg = real(alpha_gen_arg);
            save(fullfile(data_dir, sprintf('alpha_%s_module.mat', state_name)), 'alpha_mod');
            save(fullfile(data_dir, sprintf('alpha_%s_argument.mat', state_name)), 'alpha_arg');
            
            % Збереження Еліптичності (Beta)
            beta_mod = real(beta_gen_mod);
            beta_arg = real(beta_gen_arg);
            save(fullfile(data_dir, sprintf('beta_%s_module.mat', state_name)), 'beta_mod');
            save(fullfile(data_dir, sprintf('beta_%s_argument.mat', state_name)), 'beta_arg');
        end
        
        % -----------------------------------------------------------------
        % РОЗШИРЕНА АНАЛІТИКА ДЛЯ МОДУЛІВ ТА АРГУМЕНТІВ
        % -----------------------------------------------------------------
        alpha_mod_real = real(alpha_gen_mod);
        alpha_arg_real = real(alpha_gen_arg);
        beta_mod_real = real(beta_gen_mod);
        beta_arg_real = real(beta_gen_arg);
        
        % Таблиця статистичних моментів
        create_and_save_statistics_table(alpha_mod_real, alpha_arg_real, beta_mod_real, beta_arg_real, state_name, analysis_dir);
        
        % Нова структура: Модуль | Аргумент; Гістограми; АКФ
        % Для Азимута (Alpha)
        fig_alpha = figure('Visible', 'off', 'Position', [100 100 1800 1200]);
        plot_combined_analysis(fig_alpha, alpha_gen_mod, alpha_gen_arg, alpha_cl, state_name, 'Азимут (Alpha)', 50);
        saveas(fig_alpha, fullfile(analysis_dir, sprintf('Alpha_Combined_%s.png', state_name)));
        close(fig_alpha);
        
        % Для Еліптичності (Beta)
        fig_beta = figure('Visible', 'off', 'Position', [100 100 1800 1200]);
        plot_combined_analysis(fig_beta, beta_gen_mod, beta_gen_arg, beta_cl, state_name, 'Еліптичність (Beta)', 50);
        saveas(fig_beta, fullfile(analysis_dir, sprintf('Beta_Combined_%s.png', state_name)));
        close(fig_beta);
        
        % Скелетон (гістограма екстремумів) та контури
        fig_advanced = figure('Visible', 'off', 'Position', [100 100 1800 1100]);
        plot_skeleton_and_contours(fig_advanced, alpha_mod_real, alpha_arg_real, beta_mod_real, beta_arg_real, state_name);
        saveas(fig_advanced, fullfile(analysis_dir, sprintf('skeleton_contours_%s.png', state_name)));
        close(fig_advanced);
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

% =========================================================================
% ФУНКЦІЇ ДЛЯ РОЗШИРЕНОЇ АНАЛІТИКИ
% =========================================================================

function create_and_save_statistics_table(alpha_mod, alpha_arg, beta_mod, beta_arg, state_name, analysis_dir)
    % Збереження статистичних таблиць
    
    % Видалити NaN значення
    alpha_mod_valid = alpha_mod(~isnan(alpha_mod));
    alpha_arg_valid = alpha_arg(~isnan(alpha_arg));
    beta_mod_valid = beta_mod(~isnan(beta_mod));
    beta_arg_valid = beta_arg(~isnan(beta_arg));
    
    % Обчислити статистику
    stats = struct();
    
    % Alpha Module
    stats.alpha_mod_M1 = mean(alpha_mod_valid);
    stats.alpha_mod_M2 = var(alpha_mod_valid);
    stats.alpha_mod_M3 = skewness(alpha_mod_valid);
    stats.alpha_mod_M4 = kurtosis(alpha_mod_valid);
    stats.alpha_mod_min = min(alpha_mod_valid);
    stats.alpha_mod_max = max(alpha_mod_valid);
    stats.alpha_mod_median = median(alpha_mod_valid);
    stats.alpha_mod_std = std(alpha_mod_valid);
    
    % Alpha Argument
    stats.alpha_arg_M1 = mean(alpha_arg_valid);
    stats.alpha_arg_M2 = var(alpha_arg_valid);
    stats.alpha_arg_M3 = skewness(alpha_arg_valid);
    stats.alpha_arg_M4 = kurtosis(alpha_arg_valid);
    stats.alpha_arg_min = min(alpha_arg_valid);
    stats.alpha_arg_max = max(alpha_arg_valid);
    stats.alpha_arg_median = median(alpha_arg_valid);
    stats.alpha_arg_std = std(alpha_arg_valid);
    
    % Beta Module
    stats.beta_mod_M1 = mean(beta_mod_valid);
    stats.beta_mod_M2 = var(beta_mod_valid);
    stats.beta_mod_M3 = skewness(beta_mod_valid);
    stats.beta_mod_M4 = kurtosis(beta_mod_valid);
    stats.beta_mod_min = min(beta_mod_valid);
    stats.beta_mod_max = max(beta_mod_valid);
    stats.beta_mod_median = median(beta_mod_valid);
    stats.beta_mod_std = std(beta_mod_valid);
    
    % Beta Argument
    stats.beta_arg_M1 = mean(beta_arg_valid);
    stats.beta_arg_M2 = var(beta_arg_valid);
    stats.beta_arg_M3 = skewness(beta_arg_valid);
    stats.beta_arg_M4 = kurtosis(beta_arg_valid);
    stats.beta_arg_min = min(beta_arg_valid);
    stats.beta_arg_max = max(beta_arg_valid);
    stats.beta_arg_median = median(beta_arg_valid);
    stats.beta_arg_std = std(beta_arg_valid);
    
    % Зберегти таблицю у .mat файл
    save(fullfile(analysis_dir, sprintf('statistics_%s.mat', state_name)), 'stats');
    
    % Зберегти текстовий звіт
    fid = fopen(fullfile(analysis_dir, sprintf('statistics_%s.txt', state_name)), 'w');
    fprintf(fid, '=== СТАТИСТИЧНІ МОМЕНТИ СТАНУ: %s ===\n\n', state_name);
    fprintf(fid, '--- АЗИМУТ (ALPHA) МОДУЛЬ ---\n');
    fprintf(fid, 'M1 (Середнє):        %.6f\n', stats.alpha_mod_M1);
    fprintf(fid, 'M2 (Дисперсія):      %.6f\n', stats.alpha_mod_M2);
    fprintf(fid, 'M3 (Асиметрія):      %.6f\n', stats.alpha_mod_M3);
    fprintf(fid, 'M4 (Ексцес):         %.6f\n', stats.alpha_mod_M4);
    fprintf(fid, 'Мін:                 %.6f\n', stats.alpha_mod_min);
    fprintf(fid, 'Макс:                %.6f\n', stats.alpha_mod_max);
    fprintf(fid, 'Медіана:             %.6f\n', stats.alpha_mod_median);
    fprintf(fid, 'Std Відхилення:      %.6f\n\n', stats.alpha_mod_std);
    
    fprintf(fid, '--- АЗИМУТ (ALPHA) АРГУМЕНТ ---\n');
    fprintf(fid, 'M1 (Середнє):        %.6f\n', stats.alpha_arg_M1);
    fprintf(fid, 'M2 (Дисперсія):      %.6f\n', stats.alpha_arg_M2);
    fprintf(fid, 'M3 (Асиметрія):      %.6f\n', stats.alpha_arg_M3);
    fprintf(fid, 'M4 (Ексцес):         %.6f\n', stats.alpha_arg_M4);
    fprintf(fid, 'Мін:                 %.6f\n', stats.alpha_arg_min);
    fprintf(fid, 'Макс:                %.6f\n', stats.alpha_arg_max);
    fprintf(fid, 'Медіана:             %.6f\n', stats.alpha_arg_median);
    fprintf(fid, 'Std Відхилення:      %.6f\n\n', stats.alpha_arg_std);
    
    fprintf(fid, '--- ЕЛІПТИЧНІСТЬ (BETA) МОДУЛЬ ---\n');
    fprintf(fid, 'M1 (Середнє):        %.6f\n', stats.beta_mod_M1);
    fprintf(fid, 'M2 (Дисперсія):      %.6f\n', stats.beta_mod_M2);
    fprintf(fid, 'M3 (Асиметрія):      %.6f\n', stats.beta_mod_M3);
    fprintf(fid, 'M4 (Ексцес):         %.6f\n', stats.beta_mod_M4);
    fprintf(fid, 'Мін:                 %.6f\n', stats.beta_mod_min);
    fprintf(fid, 'Макс:                %.6f\n', stats.beta_mod_max);
    fprintf(fid, 'Медіана:             %.6f\n', stats.beta_mod_median);
    fprintf(fid, 'Std Відхилення:      %.6f\n\n', stats.beta_mod_std);
    
    fprintf(fid, '--- ЕЛІПТИЧНІСТЬ (BETA) АРГУМЕНТ ---\n');
    fprintf(fid, 'M1 (Середнє):        %.6f\n', stats.beta_arg_M1);
    fprintf(fid, 'M2 (Дисперсія):      %.6f\n', stats.beta_arg_M2);
    fprintf(fid, 'M3 (Асиметрія):      %.6f\n', stats.beta_arg_M3);
    fprintf(fid, 'M4 (Ексцес):         %.6f\n', stats.beta_arg_M4);
    fprintf(fid, 'Мін:                 %.6f\n', stats.beta_arg_min);
    fprintf(fid, 'Макс:                %.6f\n', stats.beta_arg_max);
    fprintf(fid, 'Медіана:             %.6f\n', stats.beta_arg_median);
    fprintf(fid, 'Std Відхилення:      %.6f\n', stats.beta_arg_std);
    fclose(fid);
end

function plot_combined_analysis(~, data_mod, data_arg, ~, state_name, param_name, max_lag)
    % Побудова комбінованого аналізу: Модуль | Аргумент
    %                                   Гістограми модуля | Гістограми аргумента
    %                                   АКФ модуля | АКФ аргумента
    
    data_mod_real = real(data_mod);
    data_arg_real = real(data_arg);
    
    % Видалити NaN значення
    mod_valid = data_mod_real(~isnan(data_mod_real));
    arg_valid = data_arg_real(~isnan(data_arg_real));
    
    % РЯДОК 1: Модуль, Аргумент (2D картинки) - БІЛЬШІ
    % Модуль
    subplot('Position', [0.05, 0.52, 0.43, 0.45]);
    imagesc(data_mod_real);
    axis image off;
    colorbar;
    colormap(gca, 'jet');
    title(sprintf('%s Модуль (Стан: %s)', param_name, state_name), 'Interpreter', 'none');
    
    % Аргумент
    subplot('Position', [0.52, 0.52, 0.43, 0.45]);
    imagesc(data_arg_real);
    axis image off;
    colorbar;
    colormap(gca, 'jet');
    title(sprintf('%s Аргумент (Стан: %s)', param_name, state_name), 'Interpreter', 'none');
    
    % РЯДОК 2: Гістограми (100 бінів)
    % Гістограма модуля
    subplot('Position', [0.05, 0.27, 0.43, 0.22]);
    histogram(mod_valid, 100, 'EdgeColor', 'none', 'FaceColor', 'blue');
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Гістограма %s Модуля', param_name));
    
    % Гістограма аргумента
    subplot('Position', [0.52, 0.27, 0.43, 0.22]);
    histogram(arg_valid, 100, 'EdgeColor', 'none', 'FaceColor', 'green');
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Гістограма %s Аргумента', param_name));
    
    % РЯДОК 3: АКФ з обмеженим діапазоном (±max_lag пікселів)
    % АКФ модуля
    subplot('Position', [0.05, 0.05, 0.43, 0.22]);
    if length(mod_valid) > 1
        [acf_mod, lags_mod] = xcorr(mod_valid - mean(mod_valid), max_lag, 'normalized');
        plot(lags_mod, acf_mod, 'LineWidth', 1.5, 'Color', 'blue');
        grid on;
        xlabel('Лаг (пікселі)');
        ylabel('АКФ');
        title(sprintf('АКФ %s Модуля', param_name));
        xlim([-max_lag, max_lag]);
    else
        text(0.5, 0.5, 'Недостатньо даних', 'HorizontalAlignment', 'center');
    end
    
    % АКФ аргумента
    subplot('Position', [0.52, 0.05, 0.43, 0.22]);
    if length(arg_valid) > 1
        [acf_arg, lags_arg] = xcorr(arg_valid - mean(arg_valid), max_lag, 'normalized');
        plot(lags_arg, acf_arg, 'LineWidth', 1.5, 'Color', 'green');
        grid on;
        xlabel('Лаг (пікселі)');
        ylabel('АКФ');
        title(sprintf('АКФ %s Аргумента', param_name));
        xlim([-max_lag, max_lag]);
    else
        text(0.5, 0.5, 'Недостатньо даних', 'HorizontalAlignment', 'center');
    end
end

function plot_histograms(~, alpha_mod, alpha_arg, beta_mod, beta_arg, state_name)
    % Побудова гістограм розподілів (100 бінів)
    num_bins = 100;
    
    % Видалити NaN значення
    am_valid = alpha_mod(~isnan(alpha_mod));
    aa_valid = alpha_arg(~isnan(alpha_arg));
    bm_valid = beta_mod(~isnan(beta_mod));
    ba_valid = beta_arg(~isnan(beta_arg));
    
    % Alpha Module
    subplot(2, 2, 1);
    histogram(am_valid, num_bins, 'EdgeColor', 'none', 'FaceColor', 'blue');
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Азимут Модуль (Стан: %s)', state_name));
    
    % Alpha Argument
    subplot(2, 2, 2);
    histogram(aa_valid, num_bins, 'EdgeColor', 'none', 'FaceColor', 'green');
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Азимут Аргумент (Стан: %s)', state_name));
    
    % Beta Module
    subplot(2, 2, 3);
    histogram(bm_valid, num_bins, 'EdgeColor', 'none', 'FaceColor', 'red');
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Еліптичність Модуль (Стан: %s)', state_name));
    
    % Beta Argument
    subplot(2, 2, 4);
    histogram(ba_valid, num_bins, 'EdgeColor', 'none', 'FaceColor', 'magenta');
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Еліптичність Аргумент (Стан: %s)', state_name));
end

function plot_acf_limited(~, alpha_mod, alpha_arg, beta_mod, beta_arg, state_name, max_lag)
    % Побудова АКФ з обмеженим діапазоном (±max_lag пікселів)
    
    % Видалити NaN значення
    am_valid = alpha_mod(~isnan(alpha_mod));
    aa_valid = alpha_arg(~isnan(alpha_arg));
    bm_valid = beta_mod(~isnan(beta_mod));
    ba_valid = beta_arg(~isnan(beta_arg));
    
    % Функція для розрахунку АКФ з обмеженням
    compute_acf = @(data) xcorr(data - mean(data), max_lag, 'normalized');
    
    % Alpha Module
    subplot(2, 2, 1);
    [acf_am, lags_am] = compute_acf(am_valid);
    plot(lags_am, acf_am, 'LineWidth', 1.5, 'Color', 'blue');
    grid on;
    xlabel('Лаг (пікселі)');
    ylabel('АКФ');
    title(sprintf('АКФ Азимут Модуль (Стан: %s)', state_name));
    xlim([-max_lag, max_lag]);
    
    % Alpha Argument
    subplot(2, 2, 2);
    [acf_aa, lags_aa] = compute_acf(aa_valid);
    plot(lags_aa, acf_aa, 'LineWidth', 1.5, 'Color', 'green');
    grid on;
    xlabel('Лаг (пікселі)');
    ylabel('АКФ');
    title(sprintf('АКФ Азимут Аргумент (Стан: %s)', state_name));
    xlim([-max_lag, max_lag]);
    
    % Beta Module
    subplot(2, 2, 3);
    [acf_bm, lags_bm] = compute_acf(bm_valid);
    plot(lags_bm, acf_bm, 'LineWidth', 1.5, 'Color', 'red');
    grid on;
    xlabel('Лаг (пікселі)');
    ylabel('АКФ');
    title(sprintf('АКФ Еліптичність Модуль (Стан: %s)', state_name));
    xlim([-max_lag, max_lag]);
    
    % Beta Argument
    subplot(2, 2, 4);
    [acf_ba, lags_ba] = compute_acf(ba_valid);
    plot(lags_ba, acf_ba, 'LineWidth', 1.5, 'Color', 'magenta');
    grid on;
    xlabel('Лаг (пікселі)');
    ylabel('АКФ');
    title(sprintf('АКФ Еліптичність Аргумент (Стан: %s)', state_name));
    xlim([-max_lag, max_lag]);
end

function plot_skeleton_and_contours(~, alpha_mod, alpha_arg, beta_mod, beta_arg, ~)
    % РЯД 1: Alpha (модуль і аргумент)
    % 1. Скелетон для Alpha Module
    subplot('Position', [0.02, 0.52, 0.12, 0.40]);
    [extrema_am, ext_values_am] = find_local_extrema(alpha_mod);
    if ~isempty(extrema_am)
        histogram(ext_values_am, 50, 'EdgeColor', 'none', 'FaceColor', 'blue');
    end
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Скелетон α Модуль'));
    
    % 2. Контури Alpha Module - БІЛЬШІ
    subplot('Position', [0.14, 0.52, 0.32, 0.40]);
    imagesc(alpha_mod); axis image; colorbar;
    colormap(gca, 'jet');
    hold on;
    alpha_mod_clean = alpha_mod;
    alpha_mod_clean(isnan(alpha_mod_clean)) = mean(alpha_mod_clean, 'all', 'omitnan');
    contour(alpha_mod_clean, 10, 'k-', 'LineWidth', 0.5);
    hold off;
    title(sprintf('Контури α Модуль'));
    
    % 3. Скелетон для Alpha Argument
    subplot('Position', [0.48, 0.52, 0.12, 0.40]);
    [extrema_aa, ext_values_aa] = find_local_extrema(alpha_arg);
    if ~isempty(extrema_aa)
        histogram(ext_values_aa, 50, 'EdgeColor', 'none', 'FaceColor', 'green');
    end
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Скелетон α Аргумент'));
    
    % 4. Контури Alpha Argument - БІЛЬШІ
    subplot('Position', [0.60, 0.52, 0.32, 0.40]);
    imagesc(alpha_arg); axis image; colorbar;
    colormap(gca, 'jet');
    hold on;
    alpha_arg_clean = alpha_arg;
    alpha_arg_clean(isnan(alpha_arg_clean)) = mean(alpha_arg_clean, 'all', 'omitnan');
    contour(alpha_arg_clean, 10, 'k-', 'LineWidth', 0.5);
    hold off;
    title(sprintf('Контури α Аргумент'));
    
    % РЯД 2: Beta (модуль і аргумент)
    % 5. Скелетон для Beta Module
    subplot('Position', [0.02, 0.05, 0.12, 0.40]);
    [extrema_bm, ext_values_bm] = find_local_extrema(beta_mod);
    if ~isempty(extrema_bm)
        histogram(ext_values_bm, 50, 'EdgeColor', 'none', 'FaceColor', 'red');
    end
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Скелетон β Модуль'));
    
    % 6. Контури Beta Module - БІЛЬШІ
    subplot('Position', [0.14, 0.05, 0.32, 0.40]);
    imagesc(beta_mod); axis image; colorbar;
    colormap(gca, 'jet');
    hold on;
    beta_mod_clean = beta_mod;
    beta_mod_clean(isnan(beta_mod_clean)) = mean(beta_mod_clean, 'all', 'omitnan');
    contour(beta_mod_clean, 10, 'k-', 'LineWidth', 0.5);
    hold off;
    title(sprintf('Контури β Модуль'));
    
    % 7. Скелетон для Beta Argument
    subplot('Position', [0.48, 0.05, 0.12, 0.40]);
    [extrema_ba, ext_values_ba] = find_local_extrema(beta_arg);
    if ~isempty(extrema_ba)
        histogram(ext_values_ba, 50, 'EdgeColor', 'none', 'FaceColor', 'magenta');
    end
    grid on;
    xlabel('Значення');
    ylabel('Частота');
    title(sprintf('Скелетон β Аргумент'));
    
    % 8. Контури Beta Argument - БІЛЬШІ
    subplot('Position', [0.60, 0.05, 0.32, 0.40]);
    imagesc(beta_arg); axis image; colorbar;
    colormap(gca, 'jet');
    hold on;
    beta_arg_clean = beta_arg;
    beta_arg_clean(isnan(beta_arg_clean)) = mean(beta_arg_clean, 'all', 'omitnan');
    contour(beta_arg_clean, 10, 'k-', 'LineWidth', 0.5);
    hold off;
    title(sprintf('Контури β Аргумент'));
end

function [extrema_idx, extrema_values] = find_local_extrema(data)
    % Пошук локальних максимумів та мінімумів
    % Функція застосовує морфологічні операції для виділення екстремумів
    
    % Видалити NaN
    data_clean = data;
    data_clean(isnan(data_clean)) = 0;
    
    % Нормалізація даних
    data_norm = (data_clean - min(data_clean(:))) / (max(data_clean(:)) - min(data_clean(:)) + eps);
    
    % Пошук локальних максимумів
    data_max = imregionalmax(data_norm);
    
    % Пошук локальних мінімумів (інвертуємо дані)
    data_min = imregionalmax(1 - data_norm);
    
    % Об'єднуємо екстремуми
    extrema_mask = data_max | data_min;
    extrema_idx = find(extrema_mask);
    
    % Отримуємо значення екстремумів
    if ~isempty(extrema_idx)
        extrema_values = data_clean(extrema_idx);
    else
        extrema_values = [];
    end
end