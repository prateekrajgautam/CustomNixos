{ config, pkgs, lib, ... }: # A NixOS module is a function that takes config, pkgs, and potentially lib as arguments [4-8]
{
  # Configure the Prometheus Node Exporter service
  services.prometheus.exporters.node = {
    # Enable the Node Exporter service
    enable = true;

    # Specify the port the exporter will listen on.
    # The default is often 9100, but you can explicitly set it here.
    port = 9100; 

    # Optionally open the necessary firewall port for the exporter.
    # This automatically adds a rule to your system's firewall.
    # openFirewall = true;
    # You can make the firewall rule more specific if needed, for example:
    # firewallFilter = "-i br0 -p tcp -m tcp --dport 9100"; [previous conversation]

    # You can specify which collectors to enable or disable for the Node Exporter.
    # By default, many common collectors are enabled.
    # To enable specific collectors (e.g., logind and systemd, while disabling textfile):
    # enabledCollectors = [ "logind" "systemd" ]; [previous conversation]
    # disabledCollectors = [ "textfile" ]; [previous conversation]

    # Any additional flags to pass to the node_exporter executable can be added here
    # extraFlags = [ "--collector.cpu.info" ];
  };
}