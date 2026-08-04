terraform {
  required_providers {
    harness = {
      source = "harness/harness"
      version = "0.44.5"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }

}

locals {
  sa_token = file("/var/run/secrets/kubernetes.io/serviceaccount/token")
  ca_cert  = file("/var/run/secrets/kubernetes.io/serviceaccount/ca.crt")
}

provider "helm" {
  kubernetes {
    in_cluster = true
  }
}

provider "harness" {
  endpoint   = "https://app.harness.io/gateway"
  account_id = "tjgVkyI9Sq63D6w9gUiVFQ"
  platform_api_key    = "${var.api_key}"
}

data "harness_platform_organization" "org" {
  identifier = "default"
}

data "harness_platform_project" "project" {
  identifier = "GitOps_Demo"
  org_id     = "default"
}


resource "harness_platform_gitops_agent" "gitops_agent" {
  identifier = "austintest-agent"
  account_id = "tjgVkyI9Sq63D6w9gUiVFQ"
  project_id = "CSE_Lab_Project"
  org_id     = "CSE_Labs"
  name       = "austintest-agent"
  type       = "MANAGED_ARGO_PROVIDER"
  metadata {
    namespace         = "austin-test-ns2"
    high_availability = false
  }
}

resource "helm_release" "gitops_agent2" {
  name       = "argocd"
  namespace  = "austin-test-ns2"
  replace = true

  repository = "https://harness.github.io/gitops-helm"
  chart      = "gitops-helm"

  values = [
    <<-YAML

    global:
      image:
        repository: docker.io/harness/argocd
        tag: v3.4.2

    # <---Harness configuration overrides--->
    harness:
      identity:
        accountIdentifier: tjgVkyI9Sq63D6w9gUiVFQ
        orgIdentifier: CSE_Labs
        projectIdentifier: CSE_Lab_Project
        agentIdentifier: austintest-agent

      secrets:
        agentSecret: "${harness_platform_gitops_agent.gitops_agent.agent_token}"
        # <---CA data overrides--->
        caData:
          enabled: false
          secret: 
        redisPassword: LKd9LNjyOSyBSg==

      gitopsServerHost: https://app.harness.io/prod1/gitops
      networkPolicy:
        create: true
      createClusterRoles: true

      configMap:
        logLevel: DEBUG

        # <---Agent communication protocol details--->
        http:
          agentHttpTarget: https://app.harness.io/gitops
          tlsEnabled: false
          certPath: /tmp/ca.bundle

        reconcile:
          appsetReconcile: true

      # <---Disaster Recovery override values--->
      disasterRecovery:
        enabled: false
        identifier: 

      # <---Openshift override values--->
      openshift:
        enabled: false
      flux:
        enabled: false
      argocdHarnessPlugin:
        enabled: false

    argo-cd:
      enabled: true

    # <---Argo CD configuration overrides--->

      ## IMPORTANT: Mark crds as false for Helm installations if they are already installed in the cluster
      crds:
        install: true
        keep: true

      configs:
        cm:
          cluster.inClusterEnabled: true

      # <---Component resource overrides--->
      controller:
        resources:
          requests:
            cpu: ".5"
            memory: 1Gi
          limits:
            cpu: "1"
            memory: 1.5Gi

      applicationSet:
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: "1"
            memory: 1Gi

      # <---Redis image details--->
      redis:
        enabled: true
        image:
          repository: docker.io/harness/redis
          tag: 7.4.8
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: "1"
            memory: 1Gi

      redisSecretInit:
        enabled: true

      # <---High Availability Agent (HA) values--->
      redis-ha:
        enabled: false
        image:
          repository: docker.io/harness/redis
          tag: 7.4.8
        haproxy:
          enabled: false
          image:
            repository: docker.io/harness/haproxy
            tag: 3.4.1-alpine3.24
        configmapTest:
          ## Image for redis-ha-configmap-test hook
          image:
            repository: docker.io/harness/shellcheck
            tag: v0.11.0
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: "1"
            memory: 1Gi

      repoServer:
        replicas:  1 
        resources:
          requests:
            cpu: "1"
            memory: 3Gi
          limits:
            cpu: "2"
            memory: 3Gi
        env:
          - name: HELM_PLUGINS
            value: /helm-sops-tools/helm-plugins/
          - name: HELM_SECRETS_CURL_PATH
            value: /helm-sops-tools/curl
          - name: HELM_SECRETS_SOPS_PATH
            value: /helm-sops-tools/sops
          - name: HELM_SECRETS_KUBECTL_PATH
            value: /helm-sops-tools/kubectl
          - name: HELM_SECRETS_BACKEND
            value: sops
          - name: HELM_SECRETS_VALUES_ALLOW_SYMLINKS
            value: "false"
          - name: HELM_SECRETS_VALUES_ALLOW_ABSOLUTE_PATH
            value: "true"
          - name: HELM_SECRETS_VALUES_ALLOW_PATH_TRAVERSAL
            value: "false"
          - name: HELM_SECRETS_WRAPPER_ENABLED
            value: "true"
          - name: HELM_SECRETS_HELM_PATH
            value: /usr/local/bin/helm
          - name: PATH
            value: /helm-sops-tools/helm-secrets:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        

        # <---SOPS override values--->
        initContainers:
          - name: sops-helm-secrets-tool
            image: docker.io/harness/gitops-agent-installer-helper:v0.0.17
            imagePullPolicy: IfNotPresent
            resources:
              requests:
                cpu: 500m
                memory: 512Mi
              limits:
                cpu: 500m
                memory: 512Mi
            command: [ sh, -ec ]
            args:
              - |
                cp -r /custom-tools/. /helm-sops-tools
                cp /helm-sops-tools/helm-plugins/helm-secrets/scripts/wrapper/helm.sh /helm-sops-tools/helm
                mkdir -p /helm-sops-tools/helm-secrets && cp /helm-sops-tools/helm-plugins/helm-secrets/scripts/wrapper/helm.sh /helm-sops-tools/helm-secrets/helm
                chmod +x /helm-sops-tools/helm-secrets/*
                chmod +x /helm-sops-tools/*
            securityContext:
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                  - ALL
              runAsNonRoot: true
              runAsUser: 65534
              seccompProfile:
                type: RuntimeDefault
            volumeMounts:
              - mountPath: /helm-sops-tools
                name: helm-sops-tools
        extraContainers:
          - command: [ /var/run/argocd/argocd-cmp-server ]
            image: docker.io/harness/gitops-agent-installer-helper:v0.0.17
            imagePullPolicy: IfNotPresent
            name: argocd-harness-plugin
            resources:
              requests:
                cpu: 500m
                memory: 512Mi
              limits:
                cpu: 500m
                memory: 512Mi
            securityContext:
              allowPrivilegeEscalation: false
              capabilities:
                drop:
                  - ALL
              runAsNonRoot: true
              runAsGroup: 999
              runAsUser: 999
              seccompProfile:
                type: RuntimeDefault
            terminationMessagePath: /dev/termination-log
            terminationMessagePolicy: File
            volumeMounts:
              - mountPath: /var/run/argocd
                name: var-files
              - mountPath: /home/argocd/cmp-server/plugins
                name: plugins
              - mountPath: /tmp
                name: tmp
              - mountPath: /home/argocd/cmp-server/config/plugin.yaml
                name: argocd-harness-plugin
                subPath: harness.yaml

    # <---Agent overrides--->
    agent:
      harnessName: austintest-agent
      image:
        repository: docker.io/harness/gitops-agent
        tag: v0.123.0

      replicas: 1
      resources:
        requests:
          cpu: 500m
          memory: 512Mi
        limits:
          cpu: "1"
          memory: 1Gi

      fipsEnabled: false

      autoscaling:
        enabled: false

      highAvailability: false
      # <---Agent Proxy Config overrides--->
      proxy:
        enabled: false
        httpProxy: 
        httpsProxy: 

    # <---Agent upgrader overrides--->
    upgrader:
      enabled: true
      image: docker.io/harness/upgrader:latest

      config:
        # -- Proxy configuration for upgrader
        # HTTPS_PROXY=proxyScheme://proxyUser:proxyPassword@proxyHost:proxyPort
        proxyHost: 
        proxyPort: 
        proxyScheme: 
        noProxy: 
        proxyUser: 
        proxyPassword: 

    YAML
  ]
}
