function importMultipleMatFiles()
    % Вибір файлів через діалогове вікно
    [files, path] = uigetfile('*.mat',...
                             'Виберіть MAT файли для імпорту',...
                             'MultiSelect', 'on');
    
    if isequal(files, 0)
        disp('Вибір файлів скасовано');
        return;
    end
    
    % Якщо вибрано лише один файл, перетворюємо на cell array
    if ~iscell(files)
        files = {files};
    end
    
    % Цикл по всіх вибраних файлах
    for i = 1:length(files)
        fileName = files{i};
        [~, baseName, ~] = fileparts(fileName); % Отримуємо ім'я без розширення
        fullPath = fullfile(path, fileName);
        
        try
            % Завантаження файлу
            loadedData = load(fullPath);
            
            % Перевірка наявності змінної cs1
            if isfield(loadedData, 'cs1')
                % Присвоєння змінній з іменем файлу
                assignin('base', baseName, loadedData.cs1);
                fprintf('Успішно імпортовано: %s\n', baseName);
            else
                % Якщо cs1 не знайдено, перевіряємо інші змінні
                vars = fieldnames(loadedData);
                if ~isempty(vars)
                    assignin('base', baseName, loadedData.(vars{1}));
                    fprintf('Імпортовано %s (змінна %s)\n', baseName, vars{1});
                end
            end
            
        catch ME
            warning('Помилка при завантаженні файлу %s: %s', fileName, ME.message);
        end
    end
    
    fprintf('Імпорт завершено!\n');
end