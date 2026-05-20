# TypeScript Style

## Project layout

```
src/
    <category>/
        module.ts
        shaders/        # WGSL shaders if applicable
            shader.wgsl
package.json
tsconfig.json
build.ts                # esbuild orchestration
```

Source lives under `src/`, organized by domain. Built output goes to `dist/` and is
never committed.

## Build tooling

- **esbuild** for compilation and bundling
- **tsc** (`tsc --noEmit`) for type-checking only -- do not use tsc for compilation
- Each `.ts` file is a separate entry point when building a module library (no
  cross-module bundling)

```json
{
    "scripts": {
        "build": "ts-node build.ts",
        "typecheck": "tsc --noEmit"
    }
}
```

## Module conventions

- Modules are self-contained -- a consumer should only need one import
- All math functions return new values, no mutation
- WebGPU modules assume `rgba32float` textures unless documented otherwise
- Mat4 is column-major `Float32Array(16)`, perspective uses WebGPU clip-Z `[0,1]`

## WGSL shaders

Shaders live in `.wgsl` files under a `shaders/` directory next to the `.ts` that
imports them. esbuild inlines them via `--loader:.wgsl=text`.

**Never embed shaders as strings in TypeScript files.** See
[File Organization](file-organization.md).

## Type declarations

For non-standard imports (WGSL, GLSL, etc.), provide ambient type declarations:

```typescript
// wgsl.d.ts
declare module "*.wgsl" {
    const content: string;
    export default content;
}
```

## Monorepo TypeScript

For npm package monorepos, use a `ts` repo with workspace configuration. Shared
`tsconfig.json` at the root, per-package overrides as needed.
