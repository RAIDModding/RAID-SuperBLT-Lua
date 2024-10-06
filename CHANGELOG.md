# RAID-SuperBLT Basemod Changelog

This lists the changes between different versions of the RAID-SuperBLT basemod,
the changes for the DLL are listed in their own changelog.
Contributors other than maintainers are listed in parenthesis after specific changes.

## v1.0.0

- based on PD2-SuperBLT v1.4.0
- patched for raid, removed linux/w32/pd2/vr codes
- included luajit from leon's repo
- Removed XAudio API
- updated libcurl with enabled http(s) features: alt-svc AsynchDNS HSTS HTTPS-proxy IPv6 Largefile libz SSL SSPI threadsafe
- updated mxml
- updated subhook
- updated wren
- updated libpng
- updated zlib, and linked curl against zlib
- removed openssl dependency - replaced sha256 impl. with Windows CNG API impl.
