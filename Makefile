test:
	zig build test -fsummary

wasm:
	zig build-lib src/main.zig -target wasm32-freestanding -dynamic
