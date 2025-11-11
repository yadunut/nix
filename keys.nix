rec {
  user = {
    yadunut = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJXOpmWsAnl2RtOuJJMRUx+iJTwf2RWJ1iS3FqXJFzFG yadunut";
    penguin-yadunut = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOEg5wsPLOZvU6lT8cMUsStQqalh/Hw5u104QhOYPS8E yadunut@penguin";
  };
  machine = {
    penguin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF0NLOa9NNz7r3QODU0Oe/a5m+PFzcpM20aLwf+0wojT root@penguin";
    nut-gc2 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN2WBYhGKSXSYWwISsY1osfliVSS9J+W6uHBid5i2qey root@nut-gc2";
  };
  users = builtins.attrValues user;
  machines = builtins.attrValues machine;
}
