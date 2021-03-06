## Подключение к GitLab

Адрес API-сервисов GitLab и токен пользователя, от лица которого будут осуществляться
запросы, указываются переменными среды `GITLAB_API_ENDPOINT` и `GITLAB_API_PRIVATE_TOKEN`.

## Проект развёртывания

Проект `deployment` содержит правила и настройки развёртывания сервисов в кластер, а также
конфигурационный файл, который описывает какие сервисы должны обрабатываться.

Идентификатор проекта развёртывания указывается переменной среды `DEPLOYMENT_PROJECT_ID`.

## Управление хуками GitLab

Если задана переменная среды `MEISTER_BASE_URL`, то автоматически будет производиться управление
web hook-ами в проектах. Если указана переменная `MEISTER_GITLAB_HOOK_SECRET`, то секрет будет
использован при установке хуков и будет проверяться при вызове.

## Конфигурационный файл

Конфигурационный файл должен лежать в корне репозитория проекта развёртывания
и называться `meister.yaml`. Формат файла:

```yaml
components:
  component_1:
    project: 12
    job: package
  component_2: 45
```

где `component_1` - имя компонента, значение ключа `project` - идентификатор проекта
в GitLab, а `job` - название шага, при успешном завершении которого срабатывает механизм
создания слепка версий (по умолчанию `deploy`). Если кроме идентификатора проекта других настроек нет, то можно использовать
сокращённую форму, как у `component_2`.

## Поддержка feature-веток

Создание feature-ветки в одном из отслеживаемых репозиториев приводит к созданию ветки
с аналогичным именем в deployment-репозитории, после чего `components.yaml` начинает обновляться
уже на конкретной ветке (а также подтягивать master-версии). Необходимо внести код из инкубатора
в этот репозиторий.

## Файл компонентов

Путь до файла указывается в конфигурационном файле значением `components_file`, по
умолчанию это файл `components.yaml` в корне репозитория. Формат файла:

```yaml
components:
  component_1:
    sha: 39f0632522c13862eff614cd48272fddc0365d2a
    ref: master
```

где `component_1` - имя компонента, соответствует имени компонента из конфигурационного файла,
`sha` - SHA-номер коммита, который привёл к последней успешной сборке компонента (образы Docker
помечены этим значением), а `ref` - название ветки, на которой происходила сборка.
