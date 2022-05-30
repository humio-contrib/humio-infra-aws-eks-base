
resource "kubectl_manifest" "humio_cluster" {
  depends_on = [
    kubernetes_namespace.humio
  ]
  yaml_body = <<-YAML
apiVersion: core.humio.com/v1alpha1
kind: HumioCluster
metadata:
  name: ${var.humio_instance}
  namespace: ${var.humio_namespace}
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: beta.humio.com/humiocluster
            operator: In
            values: 
            - "true"
          - key: kubernetes.io/arch
            operator: In
            values:
            - amd64
          - key: kubernetes.io/os
            operator: In
            values:
            - linux
          - key: eks.amazonaws.com/compute-type
            operator: NotIn
            values:
            - fargate
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - ${var.humio_instance}
        topologyKey: kubernetes.io/hostname
  autoRebalancePartitions: true
  dataVolumePersistentVolumeClaimSpecTemplate:
    accessModes:
    - ReadWriteOnce
    resources:
      requests:
        storage: 30Gi
    storageClassName: openebs-lvmpv
  dataVolumeSource: {}
  digestPartitionsCount: 720
  environmentVariables:
  - name: S3_STORAGE_BUCKET
    value: ${var.cluster_id}
  - name: S3_STORAGE_REGION
    value: ${var.region}
  - name: S3_STORAGE_ENCRYPTION_KEY
    valueFrom:
      secretKeyRef:
        key: encryption-key
        name: humio-bucket-key
  - name: USING_EPHEMERAL_DISKS
    value: "true"
  - name: S3_STORAGE_PREFERRED_COPY_SOURCE
    value: "true"
  - name: AUTHENTICATION_METHOD
    value: saml
  - name: AUTO_CREATE_USER_ON_SUCCESSFUL_LOGIN
    value: "true"
  - name: AUTO_UPDATE_GROUP_MEMBERSHIPS_ON_SUCCESSFUL_LOGIN
    value: "true"
  - name: PUBLIC_URL
    value: "https://${var.humio_instance}.${var.domain_name}"
  - name: SAML_IDP_SIGN_ON_URL
    value: ${var.sso_saml_sign_on_url}
  - name: SAML_IDP_ENTITY_ID
    value: ${var.sso_saml_entity_id}
  - name: SAML_GROUP_MEMBERSHIP_ATTRIBUTE
    value: memberOf
  - name: SMTP_HOST
    value: "email-smtp.${var.region}.amazonaws.com"
  - name: SMTP_USERNAME
    value: ${aws_iam_access_key.smtp_user.id}
  - name: SMTP_SENDER_ADDRESS
    value: "humioalerts@${var.domain_name}"
  - name: SMTP_PASSWORD
    value: ${aws_iam_access_key.smtp_user.ses_smtp_password_v4}
  - name: SMTP_PORT
    value: "587"
  - name: SMTP_USE_STARTTLS
    value: "true"
  - name: HUMIO_JVM_ARGS
    value: -Xss2m -Xms2g -Xmx6g -server -XX:MaxDirectMemorySize=6g -XX:+UnlockDiagnosticVMOptions
      -XX:CompileCommand=dontinline,com/humio/util/HotspotUtilsJ.dontInline -Xlog:gc+jni=debug:stdout
      -Dakka.log-config-on-start=on -Xlog:gc*:stdout:time,tags -Dzookeeper.client.secure=false
  - name: ZOOKEEPER_URL
    value: ${var.humio_instance}-statestore-client:2181
  - name: KAFKA_SERVERS
    value: ${var.humio_instance}-kafka-bootstrap:9092
  esHostname: humio-es.rfaircloth.com
  esHostnameSource: {}
  extraKafkaConfigs: security.protocol=PLAINTEXT
  hostname: humio.rfaircloth.com
  hostnameSource: {}
  humioServiceAccountAnnotations:
    eks.amazonaws.com/role-arn: ${tostring(module.iam_assumable_role_humio.iam_role_arn)}
  image: humio/humio-core:1.40.0
  ingress: {}
  license:
    secretKeyRef:
      key: data
      name: ${var.humio_instance}-license
  resources: {}
  storagePartitionsCount: 24
  targetReplicationFactor: 2
  tls:
    enabled: false
  tolerations:
  - effect: NoSchedule
    key: beta.humio.com/humiocluster
    operator: Exists
  - effect: NoSchedule
    key: beta.humio.com/instance-storage
    operator: Exists
YAML
}
resource "kubectl_manifest" "humio_cluster_service" {
  depends_on = [
    kubernetes_namespace.humio
  ]
  yaml_body = <<-YAML
apiVersion: v1
kind: Service
metadata:
  name: ${var.humio_instance}-ingress
  namespace: ${var.humio_namespace}
spec:
  selector:
    app.kubernetes.io/instance: ${var.humio_instance}
    app.kubernetes.io/managed-by: "humio-operator"
    app.kubernetes.io/name: ${var.humio_instance}
    humio.com/node-pool: ${var.humio_instance}

  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
  types: NodePort
YAML
}
resource "kubectl_manifest" "humio_cluster_ingress" {
  depends_on = [
    kubernetes_namespace.humio
  ]
  yaml_body = <<-YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${var.humio_instance}
  namespace: ${var.humio_namespace}
  annotations:
    alb.ingress.kubernetes.io/scheme: "internet-facing"
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: ${aws_acm_certificate.cert.arn}
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/ssl-policy: "ELBSecurityPolicy-TLS-1-2-2017-01"
    alb.ingress.kubernetes.io/listen-ports: "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
    external-dns.alpha.kubernetes.io/hostname: ${var.humio_instance}.${var.domain_name}
spec:
  ingressClassName: alb
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${var.humio_instance}-ingress
            port:
              number: 8080
              YAML

}


resource "kubectl_manifest" "job_humio_humio_setroot" {
  depends_on = [
    kubectl_manifest.humio_cluster
  ]
  yaml_body = <<-YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: humio-setroot
  namespace: humio
spec:
  template:
    spec:
      containers:
        - name: set
          image: curlimages/curl:7.83.1
          command:
            - sh
            - -c
          args:
            - >
              curl --connect-timeout 5 --max-time 10 --retry 30 --retry-delay 0 --retry-max-time 600 --retry-connrefused -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d "{\"email\": \"$EMAIL\", \"isRoot\": true}" http://humio:8080/api/v1/users
          env:
            - name: EMAIL
              value: ryan@dss-i.com
            - name: TOKEN
              valueFrom:
                secretKeyRef:
                  name: humio-admin-token
                  key: token

      restartPolicy: Never
  backoffLimit: 4
  YAML

}
