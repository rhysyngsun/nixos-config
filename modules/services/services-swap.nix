{ ... }:
{
  flake.modules.nixos.services-swap =
    { ... }:
    {
      # 64 GiB on the ext4 root. `size` is in MiB. NixOS generates a
      # `mkswap-*.service` that dd's the file from /dev/zero and runs mkswap -
      # no fallocate, so no sparse-extent problem on ext4. Merges with the
      # `swapDevices = [ ]` in the generated hardware-configuration.nix rather
      # than conflicting, because swapDevices is a list option.
      swapDevices = [
        {
          device = "/var/lib/swapfile";
          size = 64 * 1024;
        }
      ];

      boot.kernel.sysctl = {
        # Swap lives on NVMe, so anon reclaim costs about the same as file
        # reclaim. 100 makes the kernel willing to push cold desktop memory out
        # and keep LLM model pages resident. Dial back toward the 60 default if
        # the desktop feels less responsive.
        "vm.swappiness" = 100;

        # Keeps large model loads from failing allocation up front. Tradeoff:
        # malloc never fails, so over-allocation surfaces as an OOM kill rather
        # than an error - which is what the lmstudio.slice ceiling in
        # programs-ai-pi-local.nix is for.
        "vm.overcommit_memory" = 1;
      };
    };
}
