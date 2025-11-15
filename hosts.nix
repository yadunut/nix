rec {
  # Centralized machine IP addresses and deployment configuration
  machines = {
    "nut-gc1" = {
      ip = "10.222.0.13";
      user = "yadunut";
    };
    "nut-gc2" = {
      ip = "10.222.0.87";
      user = "yadunut";
    };
    penguin = {
      ip = "10.222.0.249";
      user = "root";
    };
    premhome-falcon-1 = {
      ip = "10.222.0.198";
      user = "yadunut";
    };
    premhome-eagle-1 = {
      ip = "10.222.0.118";
      user = "yadunut";
    };
    yadunut-mbp = {
      ip = "localhost";
      user = "root";
      extraArgs = {
        machineClass = "darwin";
      };
    };
  };

  # SSH keys for users and machines
  user = {
    yadunut = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXOpmWsAnl2RtOuJJMRUx+iJTwf2RWJ1iS3FqXJFzFG yadunut";
    penguin-yadunut = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOEg5wsPLOZvU6lT8cMUsStQqalh/Hw5u104QhOYPS8E yadunut@penguin";
  };
  machine = {
    penguin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0NLOa9NNz7r3QODU0Oe/a5m+PFzcpM20aLwf+0wojT root@penguin";
    nut-gc2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2WBYhGKSXSYWwISsY1osfliVSS9J+W6uHBid5i2qey root@nut-gc2";
    nut-gc1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIyKzFP+G+0jHKicqrhVjsihV4ap2p5s7U+mFZZPbbPV root@nut-gc1";
    "premhome-falcon-1" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE8zmfmBsNlPOmSv/nUSPgsoMjrTjbgqMtAsiliaLheT root@premhome-falcon-1";
    "premhome-eagle-1" =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAjNaWl6CK4YD3Y+RvC7k1uYlP+KnKa9SunTCY0Ggi0b root@premhome-eagle-1";
  };
  usersKeys = builtins.attrValues user;
  # List of machine SSH keys (machines above is the config set, so we use a different name here)
  machinesKeys = builtins.attrValues machine;
}
