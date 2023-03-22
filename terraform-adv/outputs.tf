output "vm_name_linux" {
  description = "Created linux VM name"
  value       = module.add_vm_linux.vm_name
}

output "vm_pip_linux" {
  description = "linux VM public IP"
  value       = module.add_vm_linux.pip_address
}

output "vm_name_windows" {
  description = "Created windows VM name"
  value       = module.add_vm_windows.vm_name
}

output "vm_pip_windows" {
  description = "windows VM public IP"
  value       = module.add_vm_windows.pip_address
}