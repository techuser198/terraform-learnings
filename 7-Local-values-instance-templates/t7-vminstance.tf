resource "google_compute_instance_from_template" "tech_app" {
  name = local.instance_name
  zone = local.instance_zone
  
  # Reference the instance template
  source_instance_template = google_compute_instance_template.tech_template.id
  
  depends_on = [
    google_compute_firewall.fw_ssh,
    google_compute_firewall.fw_http
  ]
}
