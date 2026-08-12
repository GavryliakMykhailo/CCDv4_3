function create_2x2_plot_mueller(data, title_prefix, filename)
    % Функція для створення зображення 2x2 з аналізом даних
    
    fig = figure('Visible', 'off', 'Position', [100 100 1200 1000]);
    
    % 1,1 - Зображення даних
    subplot(2, 2, 1);
    imagesc(data);  % Дійсна частина
    axis image off;
    colorbar;
    title([title_prefix ' - Real Part']);
    
    % 1,2 - Гістограма
    subplot(2, 2, 2);
    histogram(real(data(:)), 50, 'Normalization', 'probability');
    title([title_prefix ' - Histogram']);
    xlabel('Value');
    ylabel('Probability');
    grid on;
    
    % 1,3 - АКФ (автокореляційна функція)
    subplot(2, 2, 3);
    data_1d = real(data(:));
    if length(data_1d) > 1
        [acf, lags] = xcorr(data_1d - mean(data_1d), 'normalized');
        plot(lags, acf);
        title([title_prefix ' - ACF']);
        xlabel('Lag');
        ylabel('ACF');
        grid on;
    else
        text(0.5, 0.5, 'Insufficient data for ACF', 'HorizontalAlignment', 'center');
        title([title_prefix ' - ACF']);
    end
    
    % 1,4 - Спектр потужності
    subplot(2, 2, 4);
    data_1d = real(data(:));
    if length(data_1d) > 1
        N = length(data_1d);
        Fs = 1; % Sampling frequency
        f = Fs*(0:(N/2))/N;
        Y = fft(data_1d - mean(data_1d));
        P2 = abs(Y/N);
        P1 = P2(1:N/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        plot(f, P1);
        title([title_prefix ' - Power Spectrum']);
        xlabel('Frequency');
        ylabel('Power');
        grid on;
    else
        text(0.5, 0.5, 'Insufficient data for Spectrum', 'HorizontalAlignment', 'center');
        title([title_prefix ' - Power Spectrum']);
    end
    
    saveas(fig, filename);
    close(fig);
end