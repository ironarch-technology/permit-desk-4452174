output "bus_bootstrap_brokers" {
  value = aws_msk_cluster.bus.bootstrap_brokers
}

output "database_endpoint" {
  value = aws_db_instance.permit_desk.endpoint
}

output "attachments_bucket" {
  value = aws_s3_bucket.attachments.id
}
