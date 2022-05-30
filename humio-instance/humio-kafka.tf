resource "kubectl_manifest" "kafka_humio_humio_kafka" {
  depends_on = [
    kubernetes_namespace.humio
  ]
  yaml_body = <<-YAML
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: ${var.humio_instance}
  namespace: ${kubernetes_namespace.humio.metadata[0].name}
spec:
  cruiseControl: {}
  entityOperator: 
    topicOperator: {}
    userOperator: {}
  kafka:
    resources:
      requests:
        memory: 1Gi
        cpu: 1
      limits:
        memory: 2Gi
        cpu: 2
    config:
      default.replication.factor: 1
      offsets.topic.replication.factor: 2
      transaction.state.log.min.isr: 1
      transaction.state.log.replication.facto: 2
    listeners: 
    - name: plain
      port: 9092
      tls: false
      type: internal
    - name: tls
      port: 9093
      tls: true
      type: internal
      authentication:
        type: tls
      
    replicas: 3
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 30Gi
        deleteClaim: true
        class: ebs-gp3-enc
      
  zookeeper:
    resources:
        requests:
          memory: 256Mi
          cpu: 200m
        limits:
          memory: 256Mi
          cpu: 1
    replicas: 3
    storage:
      deleteClaim: true
      type: persistent-claim
      class: ebs-gp3-enc
      size: 1Gi    
YAML
}

resource "kubectl_manifest" "kafkarebalance_my_rebalance" {
  depends_on = [
    kubectl_manifest.kafka_humio_humio_kafka
  ]
  yaml_body = <<-YAML
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaRebalance
metadata:
  name: ${var.humio_instance}
  namepsace: ${var.humio_namespace}
  labels:
    strimzi.io/cluster: ${var.humio_instance}
spec: {}
YAML
}
