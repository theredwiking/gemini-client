# Gemini-client

> [!WARNING]
> This software is unfinished. Keep your expectations low.

All building and testing is done using zig version 0.14.0 and linux

## Todo:
- [ ] Rewrite all code
- [x] Split functions into files
- [x] Open window and render response
- [ ] Add tests
- [ ] Add lexer for gmi format
- [ ] Implement better errors and handling of them

## Build
```bash
git clone https://github.com/theredwiking/gemini-client.git
cd gemini-client
zig build -Doptimize=ReleaseFast
./zig-out/bin/gemini-client 
```
