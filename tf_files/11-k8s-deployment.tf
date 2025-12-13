# Deploy Kubernetes resources using kubectl

# Deploy Namespace
resource "null_resource" "kubectl_openwebui_namespace" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl apply -f ../yaml_files/0-namespace.yaml
    EOT
  }
}



# Deploy Open WebUi other resources
resource "null_resource" "kubectl_openwebui_deployment_1" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl apply -f ../yaml_files/1-ollama-pvc.yaml
      kubectl apply -f ../yaml_files/2-1-open-webui-pv.yaml
      kubectl apply -f ../yaml_files/2-2-open-webui-pvc.yaml
      kubectl apply -f ../yaml_files/3-secret-store.yaml
      kubectl apply -f ../yaml_files/4-external-secret.yaml
      kubectl apply -f ../yaml_files/5-config-map.yaml
      kubectl apply -f ../yaml_files/6-ollama-deployment.yaml
      kubectl apply -f ../yaml_files/7-open-webui-deployment.yaml
      kubectl apply -f ../yaml_files/8-ollama-svc.yaml
      kubectl apply -f ../yaml_files/9-open-webui-svc.yaml
      kubectl apply -f ../yaml_files/10-cf-tunnel.yaml

    EOT
  }

  depends_on = [
    null_resource.attach_uai_to_vmss,
    azurerm_key_vault_secret.webui_secret_key,
    null_resource.kubectl_openwebui_namespace
  ]

  # This ensures the null resource runs only when the Kubernetes provider resources change
  triggers = {
    always_run = "${timestamp()}"
  }
}
