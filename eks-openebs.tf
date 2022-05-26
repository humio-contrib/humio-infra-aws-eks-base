# Workaround - https://github.com/hashicorp/terraform-provider-kubernetes/issues/1380#issuecomment-967022975
resource "kubectl_manifest" "open_ebs_init" {
  depends_on = [
    module.eks
  ]
  yaml_body = <<-YAML
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: vg-init
  namespace: openebs
  labels:
    k8s-app: vg-init
spec:
  selector:
    matchLabels:
      name: vg-init
  template:
    metadata:
      labels:
        name: vg-init
    spec:
      tolerations:
        - operator: "Exists"
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: beta.humio.com/instance-storage
                    operator: Exists
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
      containers:
        - name: main
          image: ghcr.io/humio-contrib/instance-storage-init-container/container:0.4.0
          command: ["/entrypoint.sh"]
          securityContext:
            privileged: true
          resources:
            requests:
              cpu: 100m
              memory: 100Mi
            limits:
              cpu: 200m
              memory: 256Mi
YAML
}

resource "helm_release" "openebs" {
  depends_on = [
    kubectl_manifest.open_ebs_init,
    module.eks
  ]
  name             = "openebs"
  namespace        = "openebs"
  repository       = "https://openebs.github.io/charts"
  chart            = "openebs"
  version          = "3.2.0"
  create_namespace = true

  values = [<<EOF
lvm-localpv:
    enabled: true
    lvmNode:
        nodeSelector:
            beta.humio.com/instance-storage: "true"
        tolerations:
        - operator: "Exists"
    EOF
  ]

}


resource "kubectl_manifest" "storageclass_openebs_lvmpv" {
  yaml_body = <<-YAML
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: openebs-lvmpv
allowVolumeExpansion: true
parameters:
  storage: "lvm"
  volgroup: "lvmvg"
provisioner: local.csi.openebs.io
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
  YAML

  depends_on = [
    helm_release.openebs
  ]
}
