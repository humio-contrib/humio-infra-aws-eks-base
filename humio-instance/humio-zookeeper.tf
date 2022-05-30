resource "kubectl_manifest" "zookeepercluster_humio_zookeeper" {
  depends_on = [
    kubernetes_namespace.humio
  ]
  yaml_body = <<-YAML
apiVersion: "zookeeper.pravega.io/v1beta1"
kind: "ZookeeperCluster"
metadata:
  name: "${var.humio_instance}-statestore"
  namespace: ${kubernetes_namespace.humio.metadata[0].name}
spec:
  replicas: 3
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
    limits:
      cpu: 200m
      memory: 256Mi
    storageType: persistence
    persistence:
      reclaimPolicy: Delete
      spec: 
        resources:
          storage: 1Gi

  YAML
}
