resource "google_compute_instance" "tech-instance" {
  count         = var.instance_count
  name          = "tech-instance-lifecycle-${count.index + 1}"
  machine_type  = var.machine_type
  zone          = var.gcp_zone
  tags          = ["ssh-tag", "webserver-tag"]

  metadata = {
    # LIFECYCLE DEMO: Change version to trigger lifecycle events
    instance_version = var.instance_version
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")

  network_interface {
    subnetwork = google_compute_subnetwork.techsubnet.id

    access_config {
      nat_ip = null
    }
  }

  # LIFECYCLE BLOCK - Demonstrates lifecycle meta-argument
  lifecycle {
    # create_before_destroy = true
    # When true: new instance created before old one destroyed (zero-downtime)
    # When false: old destroyed then new created (short downtime)
    # USE: When you want smooth rolling updates without service interruption

    # prevent_destroy = true
    # When true: Terraform refuses to destroy this resource
    # When false: Resource can be destroyed
    # USE: For critical production resources, databases, data stores
    # Uncomment to test: terraform destroy will fail

    # ignore_changes = [metadata["instance_version"]]
    # Ignore changes to specific attributes
    # Terraform won't try to update when these fields change
    # USE: When manual changes should be ignored or for computed fields

    # replace_triggered_by = [null_resource.app_version.triggers]
    # Destroy and recreate instance when these resources change
    # USE: To trigger instance replacement on dependency changes

    create_before_destroy = true
    ignore_changes = [
      metadata["instance_version"]
    ]
  }

  # Optional: log for tracking lifecycle events
  provisioner "local-exec" {
    when       = create
    command    = "echo 'Instance ${self.name} CREATED at ${timestamp()}' >> /tmp/lifecycle.log"
    on_failure = continue
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "echo 'Instance ${self.name} DESTROYED at ${timestamp()}' >> /tmp/lifecycle.log"
    on_failure = continue
  }
}
