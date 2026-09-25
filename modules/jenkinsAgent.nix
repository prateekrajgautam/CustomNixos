{ pkgs, ... }:

let
  jenkinsUser = "jenkins";
  jenkinsGroup = "jenkins";
  
  # IMPORTANT: Using custom UID/GID to avoid conflicts with system users
  # UID 1000 is typically reserved for the first human user (e.g., prateek)
  # We use 1051 to ensure no conflicts with existing users or system services
  # This MUST match the user: setting in docker-compose.yml
  jenkinsUID = 901;
  jenkinsGID = 901;
  
  agentDir = "/zdata/jenkins/agent";
  workDir = "/zdata/jenkins/workspaces";
  jenkinsURL = "http://localhost:8080";
  agentName = "nixos-agent";
  
  # Agent secret from Jenkins UI (Manage Jenkins -> Nodes -> nixos-agent)
  agentSecret = "477d5ee0e5b0a24cc65a0920964930765c89fc3d5b9f9fb5a19c738ec5e09d29";
in
{
  # Create jenkins group with explicit GID
  users.groups.${jenkinsGroup} = {
    gid = jenkinsGID;
  };
  
  # Create jenkins user with explicit UID
  # This ensures the NixOS agent and Docker container share the same UID/GID
  users.users.${jenkinsUser} = {
    isSystemUser = true;
    group = jenkinsGroup;
    uid = jenkinsUID;
    home = agentDir;
    createHome = true;
    shell = "${pkgs.bash}/bin/bash";
  };

  systemd.services.jenkins-agent = {
    description = "Jenkins JNLP Agent Service";
    
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    
    # Add tools to PATH without overriding entire environment
    path = with pkgs; [
      jdk21
      git
      bash
      coreutils
      findutils
      gnugrep
      gnused
      gawk
      which
      curl
      wget
      gnutar
      gzip
      openssh
      python3
      nodejs
      docker
      docker-compose
      nix
      nixos-rebuild
    ];
    
    serviceConfig = {
      Type = "simple";
      User = jenkinsUser;
      Group = jenkinsGroup;
      WorkingDirectory = agentDir;

        Environment = [
    		"NIX_PATH=nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
  	];


      ExecStart = ''
        ${pkgs.jdk21}/bin/java \
          -jar ${agentDir}/agent.jar \
          -url ${jenkinsURL} \
          -secret ${agentSecret} \
          -name ${agentName} \
          -webSocket \
          -workDir "${workDir}"
      '';
      
      Restart = "always";
      RestartSec = 10;
      
      # Relax security to allow script execution in workspaces
      NoNewPrivileges = false;
      PrivateTmp = false;
      ProtectSystem = "strict";
      ReadWritePaths = [ "/zdata/jenkins" "/tmp" "/run" ];
    };
  };

  # Setup script runs during system activation
  system.activationScripts.download-jenkins-agent = {
    text = ''
      echo "Setting up Jenkins agent directories..."
      
      # Create necessary directories
      mkdir -p ${agentDir} ${workDir}
      
      # Set ownership using explicit UID/GID to match Docker container
      chown -R ${toString jenkinsUID}:${toString jenkinsGID} ${agentDir} ${workDir}
      
      # Set setgid bit on workspaces for group inheritance
      chmod 2775 ${workDir}
      
      # Download agent.jar if it doesn't exist
      if [ ! -f ${agentDir}/agent.jar ]; then
        echo "Downloading agent.jar from Jenkins controller..."
        ${pkgs.curl}/bin/curl -fsSL ${jenkinsURL}/jnlpJars/agent.jar \
          -o ${agentDir}/agent.jar 2>/dev/null || true
        
        if [ -f ${agentDir}/agent.jar ]; then
          chown ${toString jenkinsUID}:${toString jenkinsGID} ${agentDir}/agent.jar
          echo "agent.jar downloaded successfully"
        else
          echo "WARNING: Failed to download agent.jar"
          echo "You may need to download it manually after Jenkins starts"
        fi
      fi
      
      echo "Jenkins agent setup complete!"
    '';
  };
}
