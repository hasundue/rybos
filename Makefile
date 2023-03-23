test:
	zig build test -fsummary

clean:
	rm -rf main.wasm* zig-out zig-cache 

grammar:
	cd tree-sitter-rybos; bun run test

wasm:
	zig build-lib src/main.zig -target wasm32-freestanding -dynamic
