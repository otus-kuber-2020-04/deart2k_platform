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


## HW 6 templating

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


# HW7
Создал CustomResourceDefinition и CustomResource (kubernetes-operators\deploy\cr.yml и kubernetes-operators\deploy\crd.yml`)
В CustomResourceDefinition добавил validation и required
- применил CR и CRD  в кластер Kubernetes
  ```bash
  kubectl apply -f deploy/crd.yml
  kubectl apply -f deploy/cr.yml
  ```
Запустил оператор в кластере Kubernates, проверил работоспособность.

# HW8 Monitoring
1. Создал контейнер с nginx с включенным basic_status
2. Создал манифесты для Deployment, Service и ServiceMonitor
3. Проверил что мониторинг работает

Запуск:

git clone -b kubernetes-monitoring git@github.com:otus-kuber-2020-04/deart2k_platform.git
cd deart2k_platform/kubernetes-monitoring

helm upgrade --install prometheus-operator stable/prometheus-operator --create-namespace --namespace monitoring --version 9.3.0

kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f servicemonitor.yaml

Проверка:
kubectl port-forward --namespace monitoring $(kubectl get pods  --namespace monitoring --selector=app.kubernetes.io/name=grafana --output=jsonpath="{.items..metadata.name}") 3000
Пароль по умолчанию: "prom-operator", можно изменить сознанием values.yam


# HW9 Monitoring

1. Создал кластер K8s в GCP и развернул в нем HipsterShop
2. Установил EFK и  Porometheus operator используя helm
3. Так же используя helm, установил nginx-ingress и изменил конфигурацию для вывода логов в json
4. Обновил релизы с учетом доступа к kibana, grafana, prometheus через полученный ip, запустил Fluent Bit
5. Создал визуализации в kibana и сделал экспорт в файл
7. Установил и настроил Loki



## HW9 kubbernetes-vault

### ==Инсталляция hashicorp vault HA в k8s==

+ Поднимаем кластер (минимум 3 ноды):

`terraform apply`

+ Инициализируем кластер:

#`gcloud container clusters get-credentials otus-kubernetes-hw --region europe-west2-a --project inlaid-index-288607`

`gcloud container clusters list`

`gcloud container clusters get-credentials otus-kubernetes-hw`

+ Добавим репозиторий

````
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
````


+ Установим consul:

`helm upgrade --install consul hashicorp/consul`

### ==Отредактируем параметры установки в values.yaml==

```yaml
standalone:
enabled: false ....
ha:
enabled: true ...
ui:
enabled: true
  serviceType: "ClusterIP"
````
### ==Установим vault

`helm upgrade --install vault hashicorp/vault -f vault-values.yaml`

kubectl get po
NAME                                   READY   STATUS    RESTARTS   AGE
consul-consul-4rt5j                    1/1     Running   0          57s
consul-consul-p8zwg                    1/1     Running   0          57s
consul-consul-server-0                 1/1     Running   0          57s
consul-consul-server-1                 1/1     Running   0          57s
consul-consul-server-2                 1/1     Running   0          57s
consul-consul-t4m58                    1/1     Running   0          57s
vault-0                                0/1     Running   0          14s
vault-1                                0/1     Running   0          14s
vault-2                                0/1     Running   0          14s
vault-agent-injector-bdbf7b844-kr56k   1/1     Running   0          14s

+ Проверим статус:

`helm status vault `

NAME: vault
LAST DEPLOYED: Sat Sep  5 12:04:11 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get vault


- Проведем инициализацию черерз любой под vault'а kubectl

```console
kubectl exec -it vault-0 -- vault operator init --key-shares=1 --key-threshold=1

Unseal Key 1: obLat4W+Y4ohksSqSEi3E6Q7V4+27JSt5LGhfq6J0/s=

Initial Root Token: s.D0ZEUaeT4lIX9gFt71TpBLiZ


### Проверим состояние vault'а

kubectl exec -it vault-0 -- vault status
Key                Value
---                -----
Seal Type          shamir
Initialized        true
Sealed             true
Total Shares       1
Threshold          1
Unseal Progress    0/1
Unseal Nonce       n/a
Version            1.5.2
HA Enabled         true
command terminated with exit code 2


### Распечатаем vault

- Обратим внимание на переменные окружения в подах

```console
kubectl exec -it vault-0 env | grep VAULT_ADDR
VAULT_ADDR=http://127.0.0.1:8200



kubectl exec -it vault-0 -- vault operator unseal 'obLat4W+Y4ohksSqSEi3E6Q7V4+27JSt5LGhfq6J0/s='
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.5.2
Cluster Name           vault-cluster-0f14ff3e
Cluster ID             9d488102-0543-e3ab-2ce3-ee001047fc71
HA Enabled             true
HA Cluster             n/a
HA Mode                standby
Active Node Address    <none>

kubectl exec -it vault-1 -- vault operator unseal 'obLat4W+Y4ohksSqSEi3E6Q7V4+27JSt5LGhfq6J0/s='
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.5.2
Cluster Name           vault-cluster-0f14ff3e
Cluster ID             9d488102-0543-e3ab-2ce3-ee001047fc71
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.56.1.8:8200

kubectl exec -it vault-2 -- vault operator unseal 'obLat4W+Y4ohksSqSEi3E6Q7V4+27JSt5LGhfq6J0/s='
Key                    Value
---                    -----
Seal Type              shamir
Initialized            true
Sealed                 false
Total Shares           1
Threshold              1
Version                1.5.2
Cluster Name           vault-cluster-0f14ff3e
Cluster ID             9d488102-0543-e3ab-2ce3-ee001047fc71
HA Enabled             true
HA Cluster             https://vault-0.vault-internal:8201
HA Mode                standby
Active Node Address    http://10.56.1.8:8200

### Посмотрим список доступных авторизаций

Получим ошибку:

```console
kubectl exec -it vault-0 -- vault auth list
Error listing enabled authentications: Error making API request.

URL: GET http://127.0.0.1:8200/v1/sys/auth
Code: 400. Errors:

* missing client token



### Залогинимся в vault (у нас есть root token)

kubectl exec -it vault-0 -- vault login
Token (will be hidden): 
Success! You are now authenticated. The token information displayed below
is already stored in the token helper. You do NOT need to run "vault login"
again. Future Vault requests will automatically use this token.

Key                  Value
---                  -----
token                s.D0ZEUaeT4lIX9gFt71TpBLiZ
token_accessor       uvrfqqt5aNmBM2m9mLnfpXKD
token_duration       ∞
token_renewable      false
token_policies       ["root"]
identity_policies    []
policies             ["root"]


повторно запросим список авторизаций:

kubectl exec -it vault-0 -- vault auth list
Path      Type     Accessor               Description
----      ----     --------               -----------
token/    token    auth_token_0f571bc0    token based credentials



### Заведем секреты

```console
kubectl exec -it vault-0 -- vault secrets enable --path=otus kv
Success! Enabled the kv secrets engine at: otus/

 kubectl exec -it vault-0 -- vault secrets list --detailed
Path          Plugin       Accessor              Default TTL    Max TTL    Force No Cache    Replication    Seal Wrap    External Entropy Access    Options    Description                                                UUID
----          ------       --------              -----------    -------    --------------    -----------    ---------    -----------------------    -------    -----------                                                ----
cubbyhole/    cubbyhole    cubbyhole_eab07395    n/a            n/a        false             local          false        false                      map[]      per-token private secret storage                           b8076633-37d2-e1c5-fdb9-282630632d0b
identity/     identity     identity_5dd8efb9     system         system     false             replicated     false        false                      map[]      identity store                                             0952669d-f77e-9063-0dbc-c8c3654e14ea
otus/         kv           kv_a2ca1a3b           system         system     false             replicated     false        false                      map[]      n/a                                                        54c34e7e-4709-dbe5-d1b1-a426dfa2a82c
sys/          system       system_36f510ca       n/a            n/a        false             replicated     false        false                      map[]      system endpoints used for control, policy and debugging    415afeab-3b09-a84d-36dd-514b44fa4b2f


```console
kubectl exec -it vault-0 -- vault kv put otus/otus-ro/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-ro/config


kubectl exec -it vault-0 -- vault kv put otus/otus-rw/config username='otus' password='asajkjkahs'
Success! Data written to: otus/otus-rw/config
```
 kubectl exec -it vault-0 -- vault read otus/otus-ro/config
Key                 Value
---                 -----
refresh_interval    768h
password            asajkjkahs
username            otus


kubectl exec -it vault-0 -- vault kv get otus/otus-rw/config
====== Data ======
Key         Value
---         -----
password    asajkjkahs
username    otus

### Включим авторизацию черерз k8s

```console
kubectl exec -it vault-0 -- vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
```

kubectl exec -it vault-0 -- vault auth list
Path           Type          Accessor                    Description
----           ----          --------                    -----------
kubernetes/    kubernetes    auth_kubernetes_ed380490    n/a
token/         token         auth_token_fad7c4ca         token based credentials

### Создаем yaml для ClusterRoleBinding

```yml
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: role-tokenreview-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: default
```

### Создаем Service Account vault-auth и Применяем ClusterRoleBinding


```console
kubectl create serviceaccount vault-auth
serviceaccount/vault-auth created


kubectl apply -f vault-auth-service-account.yml
clusterrolebinding.rbac.authorization.k8s.io/role-tokenreview-binding created
```

### Подготовим переменные для записи в конфиг кубер авторизации

```console
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export SA_CA_CRT=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)
export K8S_HOST=$(more ~/.kube/config | grep server |awk '/http/ {print $NF}')

### alternative way
export K8S_HOST=$(kubectl cluster-info | grep 'Kubernetes master' | awk '/https/ {print $NF}' | sed 's/\x1b\[[0-9;]*m//g' )
````

### Запишем конфиг в vault


```console
kubectl exec -it vault-0 -- vault write auth/kubernetes/config \
token_reviewer_jwt="$SA_JWT_TOKEN" \
kubernetes_host="$K8S_HOST" \
kubernetes_ca_cert="$SA_CA_CRT"

Success! Data written to: auth/kubernetes/config
```


### Создаем файл политики

```json
tee otus-policy.hcl <<EOF
path "otus/otus-ro/*" {
  capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
  capabilities = ["read", "create", "list"]
}
EOF
```

### Создаем политку и роль в vault

```console
kubectl cp otus-policy.hcl vault-0:/home/vault
kubectl exec -it vault-0 -- vault policy write otus-policy /home/vault/otus-policy.hcl
Success! Uploaded policy: otus-policy
```

```console
kubectl exec -it vault-0 -- vault write auth/kubernetes/role/otus \
bound_service_account_names=vault-auth \
bound_service_account_namespaces=default policies=otus-policy ttl=24h
Success! Data written to: auth/kubernetes/role/otus
```


### Проверим как работает авторизация

- Создаем под с привязанным сервис аккоунтом и установим туда curl и jq

```console
kubectl run --generator=run-pod/v1 tmp --rm -i --tty --serviceaccount=vault-auth --image alpine:3.7
apk add curl jq
```
- Залогинимся и получим клиентский токен

curl --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  1605  100   666  100   939   4826   6804 --:--:-- --:--:-- --:--:-- 11630
{
  "request_id": "ebbf888a-1579-2cb7-f8d8-731ee579d64b",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 0,
  "data": null,
  "wrap_info": null,
  "warnings": null,
  "auth": {
    "client_token": "s.1ylKca4Embmpd8RhELSA7xaN",
    "accessor": "W62U5B4syrEfIn3fT11ZIHO0",
    "policies": [
      "default",
      "otus-policy"
    ],
    "token_policies": [
      "default",
      "otus-policy"
    ],
    "metadata": {
      "role": "otus",
      "service_account_name": "vault-auth",
      "service_account_namespace": "default",
      "service_account_secret_name": "vault-auth-token-j4d8w",
      "service_account_uid": "6dcdc583-33e3-406d-9042-99e127b587ac"
    },
    "lease_duration": 86400,
    "renewable": true,
    "entity_id": "5db49804-050b-2039-4ff2-4c7a1ea3a2f1",
    "token_type": "service",
    "orphan": true
  }
}

TOKEN=$(curl -k -s --request POST --data '{"jwt": "'$KUBE_TOKEN'", "role": "otus"}' $VAULT_ADDR/v1/auth/kubernetes/login | jq '.auth.client_token' | awk -F\" '{print $2}')

echo $TOKEN
s.D2ecJLs8CKxn7QfThqVyLd3H


### Прочитаем Прочитаем записанные ранее секреты и попробуем их обновить

- Используем свой клиентский токен
- Проверим чтение


```console
{
  "request_id": "35c59fbb-4d54-a621-9573-5a80d90c1f1a",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}

curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq

{
  "request_id": "da833800-5a39-89f1-5a4b-c68a844c9e1b",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}

- Проверим запись в otus-ro/config

curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:s.SCbMdIL61rqmyqrCUldd1ocw" $VAULT_ADDR/v1/otus/otus-ro/config | jq

{
    "errors": [
    "permission denied"
  ]
}


- Проверим запись в otus-rw/config1

```console
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq
```

```console
curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config1 | jq

{
  "request_id": "863b4552-be90-f273-cec3-773e7eaf2465",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```


- Проверим запись в otus-ro/config1

```console
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-ro/config | jq

{
  "errors": [
    "1 error occurred:\n\t* permission denied\n\n"
  ]
}
```

Доступ запрещен, так как у нас нет прав на обновление **otus/otus-ro/\***

Обновим otus-policy.hcl добавив **update**

```json
{
path "otus/otus-ro/*" {
  capabilities = ["read", "list"]
}
path "otus/otus-rw/*" {
  capabilities = ["read", "create", "update", "list"]
}
```

```console
kubectl cp otus-policy.hcl vault-0:/home/vault
kubectl exec -it vault-0 -- vault policy write otus-policy /home/vault/otus-policy.hcl
Success! Uploaded policy: otus-policy
```



- И попробуем снова записать:

```console
curl --request POST --data '{"bar": "baz"}' --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq

curl --header "X-Vault-Token:$TOKEN" $VAULT_ADDR/v1/otus/otus-rw/config | jq
{
  "request_id": "509645a1-bd6a-704e-c663-2d94ef465176",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "bar": "baz"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

Успех!!!


### Use case использования авторизации через кубер

- Авторизуемся через vault-agent и получим клиентский токен
- Через consul-template достанем секрет и положим его в nginx
- Итог - nginx получил секрет из волта, не зная ничего про волт


### Заберем репозиторий с примерами

```console
git clone https://github.com/hashicorp/vault-guides.git
cd vault-guides/identity/vault-agent-k8s-demo
```

- В каталоге configs-k8s скорректируем конфиги с учетом ранее созданых ролей и секретов
- Проверим и скорректируем конфиг example-k8s-spec.yml

### Запускаем пример

```console
kubectl apply -f configmap.yaml
configmap/example-vault-agent-config created
```
```console
kubectl get configmap example-vault-agent-config -o yaml

apiVersion: v1
data:
  consul-template-config.hcl: |
    vault {
      renew_token = false
      vault_agent_token_file = "/home/vault/.vault-token"
      retry {
        backoff = "1s"
      }
    }

    template {
    destination = "/etc/secrets/index.html"
    contents = <<EOT
    <html>
    <body>
    <p>Some secrets:</p>
    {{- with secret "otus/otus-ro/config" }}
    <ul>
    <li><pre>username: {{ .Data.username }}</pre></li>
    <li><pre>password: {{ .Data.password }}</pre></li>
    </ul>
    {{ end }}
    </body>
    </html>
    EOT
    }
  vault-agent-config.hcl: |
    exit_after_auth = true

    pid_file = "/home/vault/pidfile"

    auto_auth {
        method "kubernetes" {
            mount_path = "auth/kubernetes"
            config = {
                role = "otus"
            }
        }

        sink "file" {
            config = {
                path = "/home/vault/.vault-token"
            }
        }
    }
kind: ConfigMap
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"consul-template-config.hcl":"vault {\n  renew_token = false\n  vault_agent_token_file = \"/home/vault/.vault-token\"\n  retry {\n    backoff = \"1s\"\n  }\n}\n\ntemplate {\ndestination = \"/etc/secrets/index.html\"\ncontents = \u003c\u003cEOT\n\u003chtml\u003e\n\u003cbody\u003e\n\u003cp\u003eSome secrets:\u003c/p\u003e\n{{- with secret \"otus/otus-ro/config\" }}\n\u003cul\u003e\n\u003cli\u003e\u003cpre\u003eusername: {{ .Data.username }}\u003c/pre\u003e\u003c/li\u003e\n\u003cli\u003e\u003cpre\u003epassword: {{ .Data.password }}\u003c/pre\u003e\u003c/li\u003e\n\u003c/ul\u003e\n{{ end }}\n\u003c/body\u003e\n\u003c/html\u003e\nEOT\n}\n","vault-agent-config.hcl":"exit_after_auth = true\n\npid_file = \"/home/vault/pidfile\"\n\nauto_auth {\n    method \"kubernetes\" {\n        mount_path = \"auth/kubernetes\"\n        config = {\n            role = \"otus\"\n        }\n    }\n\n    sink \"file\" {\n        config = {\n            path = \"/home/vault/.vault-token\"\n        }\n    }\n}\n"},"kind":"ConfigMap","metadata":{"annotations":{},"name":"example-vault-agent-config","namespace":"default"}}
  creationTimestamp: "2020-09-05T13:39:10Z"
  name: example-vault-agent-config
  namespace: default
  resourceVersion: "77881"
  selfLink: /api/v1/namespaces/default/configmaps/example-vault-agent-config
  uid: fd5a3f33-b591-465d-9d99-ac4062475f13

```console
kubectl apply -f example-k8s-spec.yaml
pod/vault-agent-example created
```
### Проверим

- Законнектимся к поду nginx и вытащить оттуда index.html

```console
kubectl exec -ti vault-agent-example -c nginx-container  -- cat /usr/share/nginx/html/index.html
<html>
<body>
<p>Some secrets:</p>
<ul>
<li><pre>username: otus</pre></li>
<li><pre>password: asajkjkahs</pre></li>
</ul>

</body>
</html>
```


### Создаем CA на базе vault

- Включим pki секретс

```console
kubectl exec -it vault-0 -- vault secrets enable pki
Success! Enabled the pki secrets engine at: pki/

kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
Success! Tuned the secrets engine at: pki/\

kubectl exec -it vault-0 -- vault write -field=certificate pki/root/generate/internal common_name="example.ru" ttl=87600h > CA_cert.crt
```

### Пропишем урлы для ca и отозванных сертификатов

```console
kubectl exec -it vault-0 -- vault write pki/config/urls issuing_certificates="http://vault:8200/v1/pki/ca" crl_distribution_points="http://vault:8200/v1/pki/crl"
Success! Data written to: pki/config/urls
```

### Создаем промежуточный сертификат

```console
kubectl exec -it vault-0 -- vault secrets enable --path=pki_int pki
Success! Enabled the pki secrets engine at: pki_int/

kubectl exec -it vault-0 -- vault secrets tune -max-lease-ttl=87600h pki_int
Success! Tuned the secrets engine at: pki_int/

kubectl exec -it vault-0 -- vault write -format=json pki_int/intermediate/generate/internal common_name="example.ru Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr
```

### Пропишем промежуточный сертификат в vault

```console
kubectl cp pki_intermediate.csr vault-0:./tmp/

kubectl exec -it vault-0 -- vault write -format=json pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

kubectl cp intermediate.cert.pem vault-0:./tmp/

kubectl exec -it vault-0 -- vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem
Success! Data written to: pki_int/intermediate/set-signed
```

### Создаем и отзовем новые сертификаты

- Создаем роль для выдачи сертификатов

```console
kubectl exec -it vault-0 -- vault write pki_int/roles/example-dot-ru \
allowed_domains="example.ru" allow_subdomains=true max_ttl="720h"

Success! Data written to: pki_int/roles/example-dot-ru
````

- Создаем сертификат

```console
kubectl exec -it vault-0 -- vault write pki_int/issue/example-dot-ru common_name="test.example.ru" ttl="24h"

Key                 Value
---                 -----
ca_chain            [-----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUUac155OkUtISeH2B+1KCH+P5Xv8wDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhhbXBsZS5ydTAeFw0yMDA5MDUxMzQ1MDNaFw0yNTA5
MDQxMzQ1MzNaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOdM/mziZjht
OQg+cudjA/P5cQGT2Pc6ZGzseRLYSIaQdPsTOgW8UbY27fNjx1SLtrcS9nN9eHzU
nZEVRUObVPduxI5fO939bShcD/d8wlKdq6L86eTDwtw4f6+3bJSO43Kg5TF8Cq4w
guWN7NIU2MW4ZRkZJ3PixJqiXRCTzYbMPebrLibeqWXPy5uwdAW1g3ptRMMuWH1r
TAhIHiDlaK8l1rKi0IBhGpk5YhggHSQ38wPXYgRTiRzD+GW7FRmYQHzBQ6ilV5Xx
Gm+PslB4+RbLKNpOb81b5yCYV09vt5tcx6DvgSPhH2RpLvDgRmcyq8reOAo0VRfl
zRwE+hwzTWECAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQU84jleuQmr4qwgplaJreI21kAmOUwHwYDVR0jBBgwFoAU
4nf1UhMYDn9NGpU16KIUDwaOCqowNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
Pcu6i5X3EF7qXrdKoewF+JknEWECXMDR6hXPP03xCsgtGXEANA18ovDW6/hKnNA0
QbKOYc1QgehgcWvx30aI4uzUCHn/u+HrOY+48JqHQnfB65mBwmTEpLgsfXFEu4ez
6rZlVFHY8LzZFihHTBNW/HgX77+LV1QzCVxCkbFr6cI73cE/PMyDb+LIgRsI1KS9
lXymAYTTBldharxdopWaAeEZW2khQIftMeVJrZFI6RNXZDSAOE7G7GBL3WpW2y+u
Sfqp0L2iL9GKttDXFiZAKckpA3i6YxsB5dmJBh5JggmPxZWio/VllICIGkvnRYLs
pPZrEL9b+KLYAcfRwZoEOA==
-----END CERTIFICATE-----]
certificate         -----BEGIN CERTIFICATE-----
MIIDYzCCAkugAwIBAgIUahBgmH521m69u47HpnLKKXRvWFowDQYJKoZIhvcNAQEL
BQAwLDEqMCgGA1UEAxMhZXhhbXBsZS5ydSBJbnRlcm1lZGlhdGUgQXV0aG9yaXR5
MB4XDTIwMDkwNTEzNDY0NFoXDTIwMDkwNjEzNDcxNFowGjEYMBYGA1UEAxMPdGVz
dC5leGFtcGxlLnJ1MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoL+A
HxJ2jw9eRhS0aNCoqVUHAQ1+64MHy6K4xssDM5WFczOab9fwMHj+4CSYuRSL8zIp
y4Mx50xy8oFWhhsv9nKNobYkNNwSsTemw0lvHlJc2lZN3tY4gqXfnWfst5eGooJ5
LGl5efFJDf6jgvOJn/H/eAqQ/CwhSah3POSEU/79jrjVOIEE+zuCgUEkUtGvDVg1
s6snCd3s7JiPlwzmgnEy9SaCBTovCLsrexwPoll+GpM8xEfJ56cgy2KOmOrfaka9
J65vYEwqgFLaCE5MpdRda2FofYJiEu3LQTuo2NPPmEsmtQnMcQbCQ62DD0Fpt5R0
LcDct4Fax8KhJ9eFxQIDAQABo4GOMIGLMA4GA1UdDwEB/wQEAwIDqDAdBgNVHSUE
FjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwHQYDVR0OBBYEFKLA2rMhbrSPz6O8cifn
BXAzhTVrMB8GA1UdIwQYMBaAFPOI5XrkJq+KsIKZWia3iNtZAJjlMBoGA1UdEQQT
MBGCD3Rlc3QuZXhhbXBsZS5ydTANBgkqhkiG9w0BAQsFAAOCAQEATlvb6Pv04BbA
mCKFRz+AXD40690+QN8B9q2hMh4SGRbg7NXVTFz6LnEACkspZsXQfsFOxMYh3Jvt
U4H8wnmzP+kaZMRiMEOq6qedPJVZSm5DoF0C0OIpvxdfwqywSgY+377DtQmOjXEL
8NWSoxdIFHU0akp0D31tPxhNkVVl1lXsMjKz90ZTlubYKksDaXzkRWPkOeOeSuL6
9AhBGQzDoGCb1b3DfJmh5ro2iG4CqyJmf7eAMlpBSxfrBOj0bCce4X7me0opyZqZ
UDCc+Fiav8Iye9lv3xU1lTtcQSCcml41vP+PDJxHlJGA09Z9hu68NvR2AO278CcL
FWQQFVY1Eg==
-----END CERTIFICATE-----
expiration          1599400034
issuing_ca          -----BEGIN CERTIFICATE-----
MIIDnDCCAoSgAwIBAgIUUac155OkUtISeH2B+1KCH+P5Xv8wDQYJKoZIhvcNAQEL
BQAwFTETMBEGA1UEAxMKZXhhbXBsZS5ydTAeFw0yMDA5MDUxMzQ1MDNaFw0yNTA5
MDQxMzQ1MzNaMCwxKjAoBgNVBAMTIWV4YW1wbGUucnUgSW50ZXJtZWRpYXRlIEF1
dGhvcml0eTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOdM/mziZjht
OQg+cudjA/P5cQGT2Pc6ZGzseRLYSIaQdPsTOgW8UbY27fNjx1SLtrcS9nN9eHzU
nZEVRUObVPduxI5fO939bShcD/d8wlKdq6L86eTDwtw4f6+3bJSO43Kg5TF8Cq4w
guWN7NIU2MW4ZRkZJ3PixJqiXRCTzYbMPebrLibeqWXPy5uwdAW1g3ptRMMuWH1r
TAhIHiDlaK8l1rKi0IBhGpk5YhggHSQ38wPXYgRTiRzD+GW7FRmYQHzBQ6ilV5Xx
Gm+PslB4+RbLKNpOb81b5yCYV09vt5tcx6DvgSPhH2RpLvDgRmcyq8reOAo0VRfl
zRwE+hwzTWECAwEAAaOBzDCByTAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQU84jleuQmr4qwgplaJreI21kAmOUwHwYDVR0jBBgwFoAU
4nf1UhMYDn9NGpU16KIUDwaOCqowNwYIKwYBBQUHAQEEKzApMCcGCCsGAQUFBzAC
hhtodHRwOi8vdmF1bHQ6ODIwMC92MS9wa2kvY2EwLQYDVR0fBCYwJDAioCCgHoYc
aHR0cDovL3ZhdWx0OjgyMDAvdjEvcGtpL2NybDANBgkqhkiG9w0BAQsFAAOCAQEA
Pcu6i5X3EF7qXrdKoewF+JknEWECXMDR6hXPP03xCsgtGXEANA18ovDW6/hKnNA0
QbKOYc1QgehgcWvx30aI4uzUCHn/u+HrOY+48JqHQnfB65mBwmTEpLgsfXFEu4ez
6rZlVFHY8LzZFihHTBNW/HgX77+LV1QzCVxCkbFr6cI73cE/PMyDb+LIgRsI1KS9
lXymAYTTBldharxdopWaAeEZW2khQIftMeVJrZFI6RNXZDSAOE7G7GBL3WpW2y+u
Sfqp0L2iL9GKttDXFiZAKckpA3i6YxsB5dmJBh5JggmPxZWio/VllICIGkvnRYLs
pPZrEL9b+KLYAcfRwZoEOA==
-----END CERTIFICATE-----
private_key         -----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAoL+AHxJ2jw9eRhS0aNCoqVUHAQ1+64MHy6K4xssDM5WFczOa
b9fwMHj+4CSYuRSL8zIpy4Mx50xy8oFWhhsv9nKNobYkNNwSsTemw0lvHlJc2lZN
3tY4gqXfnWfst5eGooJ5LGl5efFJDf6jgvOJn/H/eAqQ/CwhSah3POSEU/79jrjV
OIEE+zuCgUEkUtGvDVg1s6snCd3s7JiPlwzmgnEy9SaCBTovCLsrexwPoll+GpM8
xEfJ56cgy2KOmOrfaka9J65vYEwqgFLaCE5MpdRda2FofYJiEu3LQTuo2NPPmEsm
tQnMcQbCQ62DD0Fpt5R0LcDct4Fax8KhJ9eFxQIDAQABAoIBAEizU3a6GvTItpJr
esyM0jsDQY+wUt6g/D2U8oy19FS4IwrfI9HBj9fcYSluY8QRDtqGrXBlfYRmhvY2
mLM+SIrldDjW77kYbzvHN5zK8X59MZFtxvopWJV9/4xpHB5MYY/OAo+bhF0qSygR
KlJnYq77+9aGsNvb+ZIepw7bKx3xVZ0NCDVYfsVp3LUqWY4LaQ85sKPWsIJbf/4l
ErQviuLxh2QKxPSj9z42fkP2SIZQsLGSiRSo3F5ezvWucx5xZXlAU8a9pvw5Bc17
8WSA8p9brpdmZ5iDdY5+G+f2Diegl6qo7rj9Olb+8jSkLYJffhvymSQXW+lDiz6Q
pRCyWWECgYEA0Evp0hJVg7MQuLNvMq2IEYQvtLkdONxUbanVs1jGiHpxaKM2/GgR
8Ylj6T2onq/MkX0Tg5NmhfAe8qJnLRk4ObEBzf9UH1nATl0fhg1oB75NGKCVJ/M3
qgOTYMpDIt/zbFjaEnqcF6lGztzBmr30aYhL4S91o3GYwP4mOwO0hLsCgYEAxY/l
j6thbuukcp0L7SapQHDhwDkF19nT0uvu3fW0cejMgEU0Dm2/3ztewGNGsox8R98K
/2Y0hF7w4i9cdBzIYPNUKTTHFsxMaZbrwSXJq8kSYFW01llqLJuWBlyPKyGVs4JS
QBZlP2tJ2wygkxDcO3BvSwG+i2wxQCbtAKC4t38CgYBzvbrvP8DErXtdJldjkYlK
MmlPwoy6S7OePADC51FqBJ9/xTGIj0tpKy6ZK+nGQ2kobpepRP5y7jpEGHm8VYco
h3K5RGc6BGUXJieeFVT4+IVeadx3lm4XymTaI4mql0ZrrfN+0SJrA2SVDZWGpoZp
HZMMTZLQfw6iLpaPtD9agQKBgB3mpIj1GF8QXShXqplvE4jETPap6r97oXq36MRB
Ttk6sdDsKG/Snoqr0rBtliKp7pl2IZT8JBCwyeaB4o1UWeOKkH9YFJXXv+zvQalP
DdHpMdXQwvj6OX6c4bz+v1B42c58d/RpL1PE6j20EI2RrLN2VfHVRsCVVHLwMUi6
CpsDAoGAXCpJpAj8aWZNYzMdsvqK6HlGyqMrWZ2LADk8LG25wbdS/1ZjPqzdF9Qd
mNHWTAGLLvt/QBZrmU3x9wk+FqJNLdFQOEMXFQdizgRGzB0/7ALagNuDFIq4ctYh
umhgDG/hIYzyjui7j+3zOyQkV5Gdk8/nAhts6JkJA5OoEY8XgIg=
-----END RSA PRIVATE KEY-----
private_key_type    rsa
serial_number       6a:10:60:98:7e:76:d6:6e:bd:bb:8e:c7:a6:72:ca:29:74:6f:58:5a
```

- Отзовем сертификат

```console
kubectl exec -it vault-0 -- vault write pki_int/revoke serial_number="6a:10:60:98:7e:76:d6:6e:bd:bb:8e:c7:a6:72:ca:29:74:6f:58:5a"

Key                        Value
---                        -----
revocation_time            1599313702
revocation_time_rfc3339    2020-09-05T13:48:22.291412962Z
```

### Включим TLS

Реализуем доступ к vault через https с CA из кубернетес

- Создим CSR

```console
openssl genrsa -out vault-gke.key 4096
```
vault-gke-csr.cnf

[ req ]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_ext
[ dn ]
commonName = localhost
stateOrProvinceName = Moscow
countryName = RU
emailAddress = ae@arenadata.io
organizationName = arenadata.io
organizationalUnitName = Development
[ v3_ext ]
basicConstraints = CA:FALSE
keyUsage = keyEncipherment,dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.0 = localhost
DNS.1 = vault


openssl req -config vault-gke-csr.cnf -new -key vault-gke.key -nodes -out vault.csr

base64 < "vault.csr" | tr -d '\n'

vault-csr.yaml

```yml
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: vaultcsr
spec:
  groups:
  - system:authenticated
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJRkh6Q0NBd2NDQVFBd2Z6RVNNQkFHQTFVRUF3d0piRzlqWVd4b2IzTjBNUTh3RFFZRFZRUUlEQVpOYjNOagpiM2N4Q3pBSkJnTlZCQVlUQWxKVk1SNHdIQVlKS29aSWh2Y05BUWtCRmc5aFpVQmhjbVZ1WVdSaGRHRXVhVzh4CkZUQVRCZ05WQkFvTURHRnlaVzVoWkdGMFlTNXBiekVVTUJJR0ExVUVDd3dMUkdWMlpXeHZjRzFsYm5Rd2dnSWkKTUEwR0NTcUdTSWIzRFFFQkFRVUFBNElDRHdBd2dnSUtBb0lDQVFEazkveTNpdlFSM2dUcTI3dXIvZzRoSDBxRwpNVFJPTkYrMWVXQU96K3g2dTlYdU4zMTM3WGc2aEpxQkg1cThRZElqRjVoNDBvQldMT3BuNUZsQnl5K2I2RlczCitPbE1xeHEzNnhzUHdFS1lIOUorYUZFajVad0VzaThaZmhXVDg5UGk0RkpPaTJFY0FnQmtmc0tWQzlhc2VWTjcKRG1qUnI3S1BYNW1MUDc3OEZzSTY1N3JXUEpld256L2RNUU9sNWxEdCtLQ2JRY1hKeUs4K0ZNMnZQamZMcHpoRwpNbFlaNlJId2hkZS9yYlZpaWttVC9rVUgyTjVETWwvRENCTS9HeGlwNTV0a0pPRStZUHMrMzNtT0wwMG5aSWNoClRyZGJXUk1YTnJNM0VYd2xYeUlqMHg4VHk4dkVSMzJoaXdJVTJaZ3ZYL2RWcHAwUmpQYzRYb3JZc0JNOE5RK1UKUXJWdDUrOGhhZXpGNE1ZTU1ITDZxZll5WDR2eUIrQ0RwV0s2b3BORWljQ3llM2I0OFFsazVIT2dhb0JGTTJzaQpOQ2NCMTFsczBLcEpPTWEwL2RWQ3BWOUFOT09JZkZjdm1jVW9oMHhOWElJSGVsZ3RnMlVqUTRydlNnRWFucFdUCnJ6OFhxUmR6cURUT3FWbFRsTGRoWStqbitUK3FVZ3doT01HMWNCcURXVjV5TUl4Ym5COWFVcGNsMWczWmx1UGMKMWlaZnQvV1pQT1FoUk55QTN6R1BQcHE3eHI5ck5JUVY5cHlBM1piS3I3RnZPSmNoRll3aDhqRDJMRlFOcnd6eAprZUozVzlYRW1jc2tOQmZkczMrQ1RCNzJ4Rk4vVzlHQ0xEMzhYZHFUNTZ5TnA5YnFKZXhPb214V0NSdUlBRm1XCjZkcjYybVVoU3Rwb1J0WjdzUUlEQVFBQm9Gc3dXUVlKS29aSWh2Y05BUWtPTVV3d1NqQUpCZ05WSFJNRUFqQUEKTUFzR0ExVWREd1FFQXdJRU1EQVRCZ05WSFNVRUREQUtCZ2dyQmdFRkJRY0RBVEFiQmdOVkhSRUVGREFTZ2dscwpiMk5oYkdodmMzU0NCWFpoZFd4ME1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQ0FRQ2ttRk01TGlGSXV6UlNSaE1mCmVzVm4yYzduSTYvKzVQQkxuNk1OejdTL3NEcjVtVEJIRmV4Qm1HMWYrTkN4UFRoWS9hZXVwZGdiQjRaUnZRUG8Kd2VQVHF4MUpGUmZkNUtTUURmaTdnREFlZ2VkbGdOZkM5RXVNMzdha1NWUU5LVmNLWXRlSGlaelpMZEdKNG5BRgpLZmtVNnRoM2VVeUg0Q1BvbEo2bmEreWFTREE2MXh5ODREZmFkUnpIR2lIdC9MNldhYWpKU1BOYkpQLzFXYlBNClhuVTVUWlFQZGtwSSt3THRIZWd4Vk5DRTJ3eCtGUmpDMlg3aGtNQksxOGM1YmU1UlZxaVlFYUxnd3EvQ1FBblEKWDVRMkpLQ1N3Qit0SGl0RzdMcG5kcWVvZkxwRGpCOU1Vb0FkLzUrc01taE14bjBFVmVIcDJCSnl2MnNacUtsNwoyTUkwRzdZZ0VnVU54OUM1aTVBQ054NVdPTVpEbDlwbUhLSnVIb1RPdkRBV0xocjNhOTZ1Y2VDVXpzbDJMTlYzClBLSHMyR1ZLcVM1MStQbVpjaHdHZ2xYR2JxMkpCeHRwMm5kN08yRjBpUHBOSlc0dTBsWmxQb1dwYy9UTWR1d3cKSzdHSHY4emFDeTJzK3J2MUFzZHhJbHZYNkZNczVwRy80R09pZWkvcXZIZ2wxNktpdUZYOTAvVXBFUDBOdTlVTApMekgwTlFwcG51Q1VHYndrL2ppbzBDZlZSejBmYndSbWNkU0E3UlNjanBjNUk2cXJwRWRwZXBHMTBVNkpOM1RpCko2Sy9ucnN4ZzZ1Nm1wdmtLMC9kcTJMcjY5VDRsZ0ZYaVNXZUJtdmljUk11MkozRUh6Q2tpK1FsaDlrQVIxTzgKY2FLRTM0ZW8vc0E3c0VQcDZMdzZ2ZjBDUUE9PQotLS0tLUVORCBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0K
  usages:
  - digital signature
  - key encipherment
  - server auth

```

- Применяем

```console
kubectl apply -f vault_csr.yaml
certificatesigningrequest.certificates.k8s.io/vaultcsr created

kubectl certificate approve vaultcsr
certificatesigningrequest.certificates.k8s.io/vaultcsr approved

kubectl get csr vaultcsr -o jsonpath='{.status.certificate}' | base64 --decode > vault.crt

kubectl create secret tls vault-certs --cert=vault.crt --key=vault-gke.key


```

Пересоздаем vault с новым vault-tls.values.yaml

```console
helm upgrade --install vault hashicorp/vault -f vault-tls.values.yaml
Release "vault" does not exist. Installing it now.
coalesce.go:199: warning: destination for nodeSelector is a table. Ignoring non-table value <nil>
coalesce.go:199: warning: destination for tolerations is a table. Ignoring non-table value <nil>
NAME: vault
LAST DEPLOYED: Sat Sep  5 17:46:17 2020
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Thank you for installing HashiCorp Vault!

Now that you have deployed Vault, you should look over the docs on using
Vault with Kubernetes available here:

https://www.vaultproject.io/docs/


Your release is named vault. To learn more about the release, try:

  $ helm status vault
  $ helm get vault

```

Проверяем:

```console
kubectl get secret $(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}") -o jsonpath="{.data['ca\.crt']}" | base64 --decode  > ca.crt

kubectl port-forward vault-0 8200:8200

curl --cacert ca.crt  -H "X-Vault-Token: s.Q4JOojZtdGgfiwoxJ4L3v75w" -X GET https://localhost:8200/v1/otus/otus-ro/config | jq
{
  "request_id": "ecda370b-4696-43b5-d7ad-158736974806",
  "lease_id": "",
  "renewable": false,
  "lease_duration": 2764800,
  "data": {
    "password": "asajkjkahs",
    "username": "otus"
  },
  "wrap_info": null,
  "warnings": null,
  "auth": null
}
```

### Настроить автообновление сертификатов

- Запустим nginx
- Реализуем автообнвление сертификатов для nginx c помощью vault-inject

Подготовим policy:

nginx-policy.hcl

```json
path "pki_int/issue/*" {
    capabilities = ["create", "read", "update", "list"]
}
```

Применяем:

```console
kubectl cp nginx/nginx-policy.hcl vault-0:/home/vault
kubectl exec -it vault-0 -- vault policy write nginx-policy /home/vault/nginx-policy.hcl
Success! Uploaded policy: pki-policy

kubectl exec -it vault-0 -- vault write auth/kubernetes/role/nginx-role \
        bound_service_account_names=vault-auth \
        bound_service_account_namespaces=default policies=nginx-policy ttl=24h
```

Добавим анотации в нашему поду:

```yml
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/agent-inject-status: "update"
        vault.hashicorp.com/role: "nginx-role"
        vault.hashicorp.com/agent-inject-secret-server.cert: "pki_int/issue/example-dot-ru"
        vault.hashicorp.com/agent-inject-template-server.cert: |
          {{- with secret "pki_int/issue/example-dot-ru" "common_name=nginx.example.ru" "ttl=2m" -}}
          {{ .Data.certificate }}
          {{- end }}
        vault.hashicorp.com/agent-inject-secret-server.key: "pki_int/issue/example-dot-ru"
        vault.hashicorp.com/agent-inject-template-server.key: |
          {{- with secret "pki_int/issue/example-dot-ru" "common_name=nginx.example.ru" "ttl=2m" -}}
          {{ .Data.private_key }}
          {{- end }}
        vault.hashicorp.com/service: "http://vault:8200"
        vault.hashicorp.com/agent-inject-command-server.key: "/bin/sh -c 'pkill -HUP nginx || true'"
```

> Описание [анотаций](https://www.vaultproject.io/docs/platform/k8s/injector/annotations)

Применяем:

```console
kubectl apply -f nginx/nginx-configMap.yaml -f nginx/nginx-service.yaml -f nginx/nginx-deployment.yaml
configmap/nginx-config created
service/nginx created
deployment.apps/nginx created

kubectl get pods -l app=nginx
NAME                     READY   STATUS    RESTARTS   AGE
nginx-65744668b8-2bppr   2/2     Running   0          49s
```