output "vm_name" {
  description = "Created VM name"
  value       = module.add_vm.vm_name
}

output "vm_pip" {
  description = "VM public IP"
  value       = module.add_vm.pip_address
}