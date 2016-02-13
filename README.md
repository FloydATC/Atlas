# Atlas

Atlas is a complete rewrite of the network modeling and monitoring tool we have been using in-house since 2009.
Since then, browser support for SVG and HTML5 has matured and a new web app framework called Mojolicious has emerged.
This version of Atlas tries to exploit those technologies to overcome some critical limitations of the original version,
allowing for new and exciting features that were impossible to implement in a monolithic, blocking web application.

## Please note!
**The current version is almost completely non-functional and experimental**

## Features (in random order!)
- [x] Single process for easy administration
- [x] Very simple installation. Create empty db/user/pass, edit atlas.conf, run "make tables" then start the server
- [x] Low CPU and memory requirements for monitoring hundreds, even thousands of hosts
- [x] Web GUI with intuitive panning, drag & drop
- [x] Network modeling with intuitive context-aware popup menus
- [ ] Color-coded status indication (green=alive, yellow=warning, red=dead, grey=unknown)
- [ ] Customizable icons for site/host types, comments etc.
- [ ] Support for host role tags such as P, PE, CE, C etc.
- [ ] Visual overlays to show network load, LSP status information and VLANs 
- [x] Controller, model, template and layout separation for easy customization
- [x] Non-blocking database queries and I/O
- [ ] SNMP scanning, extraction of ARP/MAC/VLAN tables where possible
- [ ] Live and historic tracing of IP and MAC addresses where possible
- [ ] Topology mismatch detection based on MAC, CDP and LLDP where possible
- [ ] Auto-configuration, backup and rollback to previous configurations (Cisco and Juniper) 
- [x] Promiscuous packet capturing thread to detect active hosts w/o ping 
- [x] Send ICMP echo requests only when needed
- [ ] Email and text message alerts with grouping, prioritization and filtering
- [ ] Flexible interface for hot import/export between Atlas and third party systems
- [ ] Flexible interface for external commands such as scripts and other shell commands
- [ ] Monitoring of servers in addition to switches/routers/etc, based on classes and templates
- [ ] Modeling and monitoring of abstract constructs such as applications and end user services  
- [x] Painfully minimalistic CSS styling done in a hurry for the sole purpose of debugging :-) 

## Test drive
https://atlas.atc.no

## WTF
- **Why use threads? Isn't the whole point of Mojolicious that it's single-threaded?** Yes for the web server. However, Atlas relies on some long-running background tasks like packet capturing and scanning which needs to run all the time. They do very little actual work themselves, instead relying on periodic HTTP requests to the web server when needed. Keeping them as threads within the Atlas process simplifies data sharing, error-checking and testing.
- **What happens if I hit the loopback URIs from a browser?** Bad things. Authentication will be added Soon[tm].
- **Why the ugly interface?** Functionality first, then design.
- **I get an error message about PCAP failing to initialize because "Operation not permitted"** Atlas needs to capture network packets in promiscuous mode, therefore it must run as root.
- **What, you're running a web server as root?!** Yes.
- **You must be insane!** Probably. Feel free to solve the problem.

