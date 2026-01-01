# TODO

## Known Issues

- [ ] WASM+WebGPU: Fullscreen transition crashes
  - Cause: sokol_app.h creates swapchain texture with size 0 during resize
  - Fix: Patch `_sapp_wgpu_create_swapchain` to guard against zero dimensions
  - Upstream: Need to file issue/PR to floooh/sokol

## Documentation

- [x] Update README: WebGPU now works (WASM)
- [ ] Update README: Add sokol.audio, sokol.shape to module list

## Ideas (from README)

### Retained Mode + Auto GC

- [ ] Pass all resources every frame, same handle = reuse
- [ ] Unused handles get garbage collected

### Blender as Editor

- [ ] Object name = script name (`elevator_01` -> `elevator_01.lua`)
- [ ] Custom properties for parameters
- [ ] glTF export/import

### Other

- [ ] Fennel + sequence macros
- [ ] Hot reload

## 3D Game Shaders Tutorial (lettier/3d-game-shaders-for-beginners)

Step-by-step port to mane3d.

### Setup

- [x] Assets: egg + textures in `assets/3d-shaders/` (gitignored)
- [ ] egg2lua.py: Convert EGG to Lua table format

### Tutorial Sections

- [ ] 4.  Reference Frames (theory)
- [ ] 5.  GLSL (sokol-shdc compatibility)
- [ ] 6.  Render To Texture
- [ ] 7.  Texturing
- [ ] 8.  Lighting
- [ ] 9.  Blinn-Phong
- [ ] 10. Fresnel Factor
- [ ] 11. Rim Lighting
- [ ] 12. Cel Shading
- [ ] 13. Normal Mapping
- [ ] 14. Deferred Rendering
- [ ] 15. Fog
- [ ] 16. Blur
- [ ] 17. Bloom
- [ ] 18. SSAO
- [ ] 19. Motion Blur
- [ ] 20. Chromatic Aberration
- [ ] 21. Screen Space Reflection
- [ ] 22. Screen Space Refraction
- [ ] 23. Foam
- [ ] 24. Flow Mapping
- [ ] 25. Outlining
- [ ] 26. Depth Of Field
- [ ] 27. Posterization
- [ ] 28. Pixelization
- [ ] 29. Sharpen
- [ ] 30. Dilation
- [ ] 31. Film Grain
- [ ] 32. Lookup Table (LUT)
- [ ] 33. Gamma Correction

## Testing

- [ ] sokol.audio bindings
- [ ] sokol.shape bindings
