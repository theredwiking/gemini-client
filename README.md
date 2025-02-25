# Gemini-client

> [!WARNING]
> This software is unfinished. Keep your expectations low.

All building and testing is done using zig version 0.13.0 and linux

## Todo:
- [ ] Rewrite all code
- [ ] Split functions into files
- [ ] Open window and render response
- [ ] Add tests

## Build
```bash
git clone https://github.com/theredwiking/gemini-client.git
cd gemini-client
zig build
./zig-out/bin/gemini-protocol gemini://geminiprotocol.net/
```

## Upgrading
When zig version 0.14.0 is released, it is need to upgrade to newest tls.zig version.
It is also need to change line 61 in src/main.zig from
```zig
var root_ca = try tls.CertBundle.fromSystem(allocator);
```
to
```zig
var root_ca = try tls.config.CertBundle.fromSystem(allocator);
```
