output "cluster_id" {
  value = module.eks.cluster_id
}

output "node_security_group_id" {
  value = module.eks.node_security_group_id
}
