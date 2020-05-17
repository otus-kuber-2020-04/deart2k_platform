# deart2k_platform
deart2k Platform repository


# HW 1

 Hа ubuntu 20.04 били установлены kubectl из snap пакета, docker из репозитория ubuntu и minikube по иструкции с сайта https://kubernetes.io/docs/tasks/tools/install-minikube/
Так же был установлен k9s. Проверил работоспособномть кластера.

Создан Dockerfile, собран docker образ и запушен на DockerHub для создания контейнеров удовлетворяющих следующим требованиям:
    * web-сервер на порту 8000 (можно использовать любой способ)
    * Отдающий содержимое директории /app внутри контейнера (например, если в директории /app лежит файл homework.html, то при запуске контейнера данный файл должен быть доступен по [URL](http://localhost:8000/homework.html)
    * Работающий с UID 1001

Создан web-pod.yaml с описанием пода, в котором исользуется созданный образ и init контейнер для генерации содержимого папки /app
Под создан, простестирован вывод странички после порт-форварда на порту 8000


Был склонирован репозиторий Hipster Shop и собран образ Docker приложения 'frontend' и запушен в  DockerHub.
Создан под в котором был запущен этот контейнер с использованием  ad-hoc режима kubectl, затем был генерован манифест средствами kubectl для этого пода и сохранен в frontend-pod.yaml:

Задание со *:

    в выводе журнала приложения видно, что не были объявленны переменные среды выполнения:

    ```kubectl logs frontend
    panic: environment variable "PRODUCT_CATALOG_SERVICE_ADDR" not set
    
    Необходимые переменные были добавлены в файле frontend-pod-healthy.yaml

# HW 2
Был создан ReplicaSet для hipster-frontend. 
После изменения и применения шаблона ReplicaSet не применил новый шаблон к уже работаюшим подам, они продолжили работать без изменений, используя старый образ.
После увеличения количества реплик, новые поды были созданы по новому шаблону, т.е. не умеет обновлять поды если изменился шаблон, но применяет изменения для новых контейнеров.

Был содан и опубликован образ для сервиса hipster-paymentservice. Созданы сначала ReplicaSet, а затем deployment с использованием этого образа. 
Были опыты с изменением  и применением новой конфигурации deployment. Deployment удаляет поды сознынные по старому шаблону и созает новые. При этом для каждого изменения
создается свой ReplicaSet и изменения можно откатить

### Задание со *
С использованием параметров maxSurge и maxUnavailable были реализованы два следующих сценария

#1 Аналог blue-green:
1. Развертывание трех новых pod
2. Удаление трех старых pod

maxSurge = **100%**
maxUnavailable = **0**

#2

Reverse Rolling Update:
1. Удаление одного старого pod
2. Создание одного нового pod
и т.д.

maxSurge = **0**
maxUnavailable = **1**

Созданы paymentservice-deployment-bg.yaml и paymentservice-deployment-reverse.yaml

### Probes

Создан frontend-deployment.yaml в который была добавлена проверка доступности пода с использованием probes.


### DaemonSet *

Найден в сети daemonset с node-exporter в который были внесены изменения для на всех нодах кластера.

```
NAME            DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
node-exporter   6         6         5       0            5           kubernetes.io/os=linux   8m

Проверена доступность метрик после проброса порта  по url localhost:9100/metrics

