import NetworkExtension
import os.log

class PacketTunnelProvider: NEPacketTunnelProvider {
    private let log = OSLog(subsystem: "com.quocchien.qcmodules.tunnel", category: "PacketTunnel")
    private var blockedDomains: Set<String> = []

    override func startTunnel(options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        os_log("Starting tunnel", log: log, type: .info)

        if let domains = options?["blockedDomains"] as? [String] {
            blockedDomains = Set(domains.map { $0.lowercased() })
        } else if let saved = UserDefaults(suiteName: "group.com.quocchien.qcmodules")?.stringArray(forKey: "blocked_domains") {
            blockedDomains = Set(saved.map { $0.lowercased() })
        }

        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        settings.mtu = 1500

        let ipv4 = NEIPv4Settings(addresses: ["192.168.0.1"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        settings.ipv4Settings = ipv4

        let dns = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        settings.dnsSettings = dns

        setTunnelNetworkSettings(settings) { error in
            if let error = error {
                os_log("Failed to set settings: %{public}@", log: self.log, type: .error, error.localizedDescription)
                completionHandler(error)
                return
            }
            self.readPackets()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        os_log("Stopping tunnel", log: log, type: .info)
        completionHandler()
    }

    private func readPackets() {
        packetFlow.readPackets { [weak self] packets, protocols in
            guard let self = self else { return }
            var allowedPackets: [Data] = []
            var allowedProtocols: [NSNumber] = []

            for (index, packet) in packets.enumerated() {
                if self.shouldBlock(packet) {
                    continue
                }
                allowedPackets.append(packet)
                allowedProtocols.append(protocols[index])
            }

            if !allowedPackets.isEmpty {
                self.packetFlow.writePackets(allowedPackets, withProtocols: allowedProtocols)
            }
            self.readPackets()
        }
    }

    private func shouldBlock(_ packet: Data) -> Bool {
        // Simple check: if packet contains a blocked domain string, drop it
        guard let text = String(data: packet, encoding: .utf8)?.lowercased() else { return false }
        for domain in blockedDomains {
            if text.contains(domain) {
                return true
            }
        }
        return false
    }
}
