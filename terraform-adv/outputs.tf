output "vm_name_windows" {
  description = "Created windows VM name"
  value       = module.add_vm_windows.vm_name
}

output "vm_pip_windows" {
  description = "windows VM public IP"
  value       = module.add_vm_windows.pip_address
}