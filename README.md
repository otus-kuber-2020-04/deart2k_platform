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
```

# HW 3 Security

### task01;
Были созданы Service Account bob и dave, аккаунту bob была дана роль admin в рамках всего
кластера

### task02
Создана Namespace prometheus и  Service Account carol в этом Namespace
Всем Service Account в Namespace prometheus была выдана возможность делать get, list, watch в отношении Pods всего кластера

### task03

Создан Namespace dev, Service Account-ы jane и ken в этом Namespace, jane выдана роль admin, а  ken роль view в рамках Namespace dev

# HW 4 networks 

#В процессе сделано:

Добавлены проверки работоспособности в под web .
Был создан Deployment для запуска web приложения.
Был создан сервис ClusterIP (kubernetes-networks/web-svc-cip.yaml)
Включен IPVS в minikube
Развернут MetalLB
Создан сервис LoadBalancer для приложения
Развернут Ingress Nginx
Приложение опубликовано через ingress http://<ingress_lb_ip>/web

# HW 5 Volumes


В процессе выполнения ДЗ:
- Познакомились с StatefulSet
- Развернули minio


# HW 6 templating


Зарегистрировал новую учетную запись в GCP
Запустил кластер kubernetes в GCP

```
gcloud container clusters create otus-claster
``` 


Установил Helm3 из snap репозитория

Установил и настроил nginx-ingress, cert-manager, chartmuseum, harbor
```
kubectl create ns nginx-ingress

helm upgrade --install nginx-ingress stable/nginx-ingress --wait --namespace=nginx-ingress --version=1.38.0

kubectl create ns cert-manager

helm install   cert-manager jetstack/cert-manager   --namespace cert-manager   --version v0.15.1 --set installCRDs=true

kubectl get pods --namespace cert-manager

kubectl apply -f test-resources.yaml

kubectl describe certificate -n cert-manager-test

kubectl apply -f clusterissuer.yaml

kubectl create ns chartmuseum

helm upgrade --install chartmuseum stable/chartmuseum --wait --namespace=chartmuseum --version=2.3.2 -f kubernetes-templating/chartmuseum/values.yaml

helm ls -n chartmuseum

kubectl get secrets -n chartmuseum

helm repo add harbor https://helm.goharbor.io

helm upgrade --install harbor harbor/harbor --wait --namespace=harbor --version=1.1.2 -f kubernetes-templating/harbor/values.yaml
```

Создал helm-chart для hipster-shop (kubernetes-templating/hipster-shop)
```bash
kubectl create ns hipster-shop
helm upgrade --install hipster-shop kubernetes-templating/hipster-shop --namespace hipster-shop
```

Сервис frontend  вынес в отдельный helm-chart, добавил его к зависимостям hipster-shop
```bash
helm upgrade --install frontend kubernetes-templating/frontend --namespace hipster-shop
```
 Чарт frontend добавлен как зависимость в чарт hipster-shop [Chart.yaml](kubernetes-templating/hipster-shop/Chart.yaml)
```yaml
dependencies:
  - name: frontend
    version: 0.1.0
    repository: "file://../frontend"
```

Вынес сервисы paymentservice и shippingservice для использования в kubecfg, создал service.jsonnet для генерации манифестов для paymentservice и shippingservice

```bash
kubecfg show kubernetes-templating/kubecfg/services.jsonnet
kubecfg update kubernetes-templating/kubecfg/services.jsonnet --namespace hipster-shop
```

Создал service.jsonnet для генерации манифестов для paymentservice и shippingservice и вынес сервис recommendationservice для использования в kustomize, 
Настроил kustomize для окружений dev и prod

```bash
kubectl apply -k kubernetes-templating/kustomize/overrides/dev
kubectl apply -k kubernetes-templating/kustomize/overrides/prod
```


