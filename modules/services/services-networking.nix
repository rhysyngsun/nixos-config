{ ... }:
{
  flake.modules.nixos.services-networking =
    { ... }:
    {
      # The BE201 (8086:272B) runs on iwlmld, where power management is
      # governed by power_scheme (1=CAM, 2=balanced, 3=low power).
      # iwlwifi.power_save is the legacy iwldvm knob and has no effect on this
      # chipset. Dozing through beacons starves the roaming logic of RSSI
      # samples, which on MIT's dense WLAN produces continuous
      # leave-and-rejoin: 20 associations across 8 BSSIDs in 40 minutes, every
      # drop locally generated.
      boot.extraModprobeConfig = ''
        options iwlmld power_scheme=1
      '';

      # Belt and braces: the modprobe option sets the driver's own scheme,
      # this stops NetworkManager re-enabling power save per connection.
      networking.networkmanager.wifi.powersave = false;
    };
}
