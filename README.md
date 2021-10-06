# Moesif Plugin for NGINX Ingress Controller

[NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/) built around Kubernetes Ingress resource, using a ConfigMap to store the NGINX configuration. This plugin will log API calls to [Moesif](https://www.moesif.com) for API analytics and monitoring.

[Github Repo](https://github.com/Moesif/moesif-nginx-ingress-plugin)

## How to Install

#### Clone to repo

We'll clone this [repo](https://github.com/Moesif/moesif-nginx-ingress-plugin) which has the codebase to create configmap, mount the plugin, and enable it during the build time.

## How to Use

#### Create a namespace
Once the repo is clone, we'll create an `ingress-nginx` namespace.

```bash
kubectl apply -f namespace.json
```

#### Create a configmap for Moesif
After an `ingress-nginx` namespace is created, we'll create a configmap for the moesif plugin.

```bash
kubectl create -n ingress-nginx configmap moesif-plugin --from-file=moesif/ 
```

#### Create a configmap for Luasocket

We'll also create a configmap for the `luasocket` library.

```bash
kubectl create -n ingress-nginx configmap moesif-socket-plugin --from-file=moesif/socket/
```
Please note that, we're creating configmap for luasocket as to avoid installing luarocks and luasocket at runtime, since the moesif plugin depends on luasocket.

#### Deploy the nginx ingress controller

Before we install the nginx ingress controller, we'll have to update the `controller-deployment.yaml` file to mount and enable config. Please refer to the Nginx Ingress Controller [Installation Guide](https://kubernetes.github.io/ingress-nginx/deploy/) if you're using another method to enable ingress. You could also refer to the default deployment used by [Nginx Ingress Controller](https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.3/deploy/static/provider/cloud/deploy.yaml).

We're enabling the moesif plugin, configuring it, and setting the identify variable which Moesif uses downstream.

```yaml
# Source: ingress-nginx/templates/controller-configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    helm.sh/chart: ingress-nginx-4.0.2
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/version: 1.0.1
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  plugins: "moesif"
  server-snippet: "set $moesif_req_body nil; set $moesif_res_body nil; set $moesif_user_id nil; set $moesif_company_id nil; set $moesif_application_id <Your Moesif Application Id>;"

```

Your Moesif Application Id can be found in the [_Moesif Portal_](https://www.moesif.com/).
After signing up for a Moesif account, your Moesif Application Id will be displayed during the onboarding steps. 

You can always find your Moesif Application Id at any time by logging 
into the [_Moesif Portal_](https://www.moesif.com/), click on the top right menu,
and then clicking _API Keys_.

Please note that `Moesif Application Id` is required to be updated to capture api calls to your account. Also, don't remove the any of the identity variable set in `server-snippet` directive as Moesif plugin uses it downstream. Additionally, you'd add other moesif config in `server-snippet` for example `set $debug true;`.

Next, we'll have to mount the plugins and set the Lua path in the nginx ingress controller deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    helm.sh/chart: ingress-nginx-4.0.2
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/version: 1.0.1
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/component: controller
  name: ingress-nginx-controller
  namespace: ingress-nginx
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: ingress-nginx
      app.kubernetes.io/instance: ingress-nginx
      app.kubernetes.io/component: controller
  revisionHistoryLimit: 10
  minReadySeconds: 0
  template:
    metadata:
      labels:
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/instance: ingress-nginx
        app.kubernetes.io/component: controller
    spec:
      dnsPolicy: ClusterFirst
      containers:
        - name: controller
          image: k8s.gcr.io/ingress-nginx/controller:v1.0.1@sha256:26bbd57f32bac3b30f90373005ef669aae324a4de4c19588a13ddba399c6664e
          imagePullPolicy: IfNotPresent
          lifecycle:
            preStop:
              exec:
                command:
                  - /wait-shutdown
          args:
            - /nginx-ingress-controller
            - --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
            - --election-id=ingress-controller-leader
            - --controller-class=k8s.io/ingress-nginx
            - --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
            - --validating-webhook=:8443
            - --validating-webhook-certificate=/usr/local/certificates/cert
            - --validating-webhook-key=/usr/local/certificates/key
          securityContext:
            capabilities:
              drop:
                - ALL
              add:
                - NET_BIND_SERVICE
            runAsUser: 101
            allowPrivilegeEscalation: true
          env:
            - name: POD_NAME
              valueFrom:
                fieldRef:
                  fieldPath: metadata.name
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            - name: LD_PRELOAD
              value: /usr/local/lib/libmimalloc.so
            - name: LUA_CPATH
              value: "/usr/local/lib/lua/?/?.so;/usr/local/lib/lua/?.so;/etc/nginx/lua/plugins/moesif/?.so;;"
            - name: LUA_PATH
              value: "/usr/local/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/lib/lua/?.lua;/etc/nginx/lua/plugins/moesif/?.lua;;"
          livenessProbe:
            failureThreshold: 5
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
          readinessProbe:
            failureThreshold: 3
            httpGet:
              path: /healthz
              port: 10254
              scheme: HTTP
            initialDelaySeconds: 10
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
          ports:
            - name: http
              containerPort: 80
              protocol: TCP
            - name: https
              containerPort: 443
              protocol: TCP
            - name: webhook
              containerPort: 8443
              protocol: TCP
          volumeMounts:
            - name: webhook-cert
              mountPath: /usr/local/certificates/
              readOnly: true
            - name: "moesif-plugin"
              mountPath: "/etc/nginx/lua/plugins/moesif"
            - name: "moesif-socket-plugin"
              mountPath: "/etc/nginx/lua/plugins/moesif/socket"
          resources:
            requests:
              cpu: 100m
              memory: 90Mi
      nodeSelector:
        kubernetes.io/os: linux
      serviceAccountName: ingress-nginx
      terminationGracePeriodSeconds: 300
      volumes:
        - name: webhook-cert
          secret:
            secretName: ingress-nginx-admission
        - name: "moesif-plugin"
          configMap:
            name: "moesif-plugin"
        - name: "moesif-socket-plugin"
          configMap:
            name: "moesif-socket-plugin"

```

Please note that you'll have to edit the lua path if you've other lua packages at different location.

```yaml
- name: LUA_CPATH
    value: "/usr/local/lib/lua/?/?.so;/usr/local/lib/lua/?.so;/etc/nginx/lua/plugins/moesif/?.so;;"
- name: LUA_PATH
    value: "/usr/local/share/luajit-2.1.0-beta3/?.lua;/usr/local/share/lua/5.1/?.lua;/usr/local/lib/lua/?.lua;/etc/nginx/lua/plugins/moesif/?.lua;;"
```

We're attaching the configmap and mounting the files. We've updated the lua path and cpath to look for files at this location.

```yaml
volumes:
  - name: webhook-cert
    secret:
      secretName: ingress-nginx-admission
  - name: "moesif-plugin"
    configMap:
      name: "moesif-plugin"
  - name: "moesif-socket-plugin"
    configMap:
      name: "moesif-socket-plugin"
```

```yaml
volumeMounts:
  - name: webhook-cert
    mountPath: /usr/local/certificates/
       readOnly: true
  - name: "moesif-plugin"
    mountPath: "/etc/nginx/lua/plugins/moesif"
  - name: "moesif-socket-plugin"
    mountPath: "/etc/nginx/lua/plugins/moesif/socket"
```

Finally, to deploy the nginx ingress controller -

```bash
kubectl apply -f controller-deployment.yaml
```

Allow sometime for the nginx-ingress-controller pod to be in a `running` stage before making requests. Congratulations! If everything was done correctly, Moesif should now be tracking all network requests that match the route you've specified in `nginx.conf`. If you have any issues with set up, please reach out to support@moesif.com.


## Configuration options

#### __`moesif_application_id`__
(__required__), _string_, Application Id to authenticate with Moesif.

#### __`disable_capture_request_body`__
(optional) _boolean_, An option to disable logging of request body. `false` by default.

#### __`disable_capture_response_body`__
(optional) _boolean_, An option to disable logging of response body. `false` by default.

#### __`request_header_masks`__
(optional) _string_, An option to mask a specific request header fields. Separate multiple fields by comma such as `"header_a, header_b"`

#### __`request_body_masks`__
(optional) _string_, An option to mask a specific request body fields. Separate multiple fields by comma such as `"field_a, field_b"`

#### __`response_header_masks`__
(optional) _string_, An option to mask a specific response header fields. Separate multiple fields by comma such as `"header_a, header_b"`

#### __`response_body_masks`__
(optional) _string_, An option to mask a specific response body fields. Separate multiple fields by comma such as `"field_a, field_b"`

#### __`disable_transaction_id`__
(optional) _boolean_, Setting to true will prevent insertion of the <code>X-Moesif-Transaction-Id</code> header. `false` by default.

#### __`debug`__
(optional) _boolean_, Set to true to print debug logs if you're having integration issues.

#### __`authorization_header_name`__
(optional) _string_, Request header field name to use to identify the User in Moesif. Defaults to `authorization`. Also, supports a comma separated string. We will check headers in order like `"X-Api-Key,Authorization"`.

#### __`authorization_user_id_field`__
(optional) _string_, Field name to parse the User from authorization header in Moesif. Defaults to `sub`.

##  Identifying users

This plugin will automatically identify API users so you can associate API traffic to web traffic and create cross-platform funnel reports of your customer journey.
The default algorithm covers most authorization designs and works as follows:

1. If the `moesif_user_id_header` option is set, read the value from the specified HTTP header key `moesif_user_id_header`.
2. Else if Nginx defined a value for `credentials.app_id`, `credentials.user_key`, or `userid` (in that order), use that value.
3. Else if an authorization token is present in `authorization_header_name`, parse the user id from the token as follows:
   * If header contains `Bearer`, base64 decode the string and use the value defined by `authorization_user_id_field` (by default is `sub`).
   * If header contains `Basic`, base64 decode the string and use the username portion (before the `:` character).

For advanced configurations, you can define a custom header containing the user id via `moesif_user_id_header` or override the options `authorization_header_name` and `authorization_user_id_field`.

## Identifying companies

You can associate API users to companies for tracking account-level usage. This can be done either:
1. Defining `moesif_company_id_header`, Moesif will use the value present in that header. 
2. Use the Moesif [update user API](https://www.moesif.com/docs/api#update-a-user) to set a `company_id` for a user. Moesif will associate the API calls automatically.

## Other integrations

To view more documentation on integration options, please visit __[the Integration Options](https://www.moesif.com/docs/getting-started/integration-options/).__