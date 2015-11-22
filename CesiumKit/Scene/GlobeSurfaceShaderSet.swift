//
//  GlobeSurfaceShaderSet.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 15/06/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

import Foundation

struct GlobeSurfacePipeline {
    
    var numberOfDayTextures: Int
    
    var flags: Int
    
    var pipeline: RenderPipeline
}

/**
* Manages the shaders used to shade the surface of a {@link Globe}.
*
* @alias GlobeSurfaceShaderSet
* @private
*/
class GlobeSurfaceShaderSet {
    
    let baseVertexShaderSource: ShaderSource
    let baseFragmentShaderSource: ShaderSource
    
    let vertexDescriptor: VertexDescriptor
    
    private var _pipelinesByTexturesFlags = [Int: [Int: GlobeSurfacePipeline]]()
    private var _pickPipelines = [Int: RenderPipeline]()
    
    init (
        baseVertexShaderSource: ShaderSource,
        baseFragmentShaderSource: ShaderSource,
        vertexDescriptor: VertexDescriptor) {
            self.baseVertexShaderSource = baseVertexShaderSource
            self.baseFragmentShaderSource = baseFragmentShaderSource
            self.vertexDescriptor = vertexDescriptor
    }
    
    private func getPositionMode(sceneMode: SceneMode) -> String {
        let getPosition3DMode = "vec4 getPosition(vec3 position3DWC) { return getPosition3DMode(position3DWC); }"
        let getPosition2DMode = "vec4 getPosition(vec3 position3DWC) { return getPosition2DMode(position3DWC); }"
        let getPositionColumbusViewMode = "vec4 getPosition(vec3 position3DWC) { return getPositionColumbusViewMode(position3DWC); }"
        let getPositionMorphingMode = "vec4 getPosition(vec3 position3DWC) { return getPositionMorphingMode(position3DWC); }"
        
        let positionMode: String
        
        switch sceneMode {
        case SceneMode.Scene3D:
            positionMode = getPosition3DMode
        case SceneMode.Scene2D:
            positionMode = getPosition2DMode
        case SceneMode.ColumbusView:
            positionMode = getPositionColumbusViewMode
        case SceneMode.Morphing:
            positionMode = getPositionMorphingMode
        }
        
        return positionMode
    }
    
    func get2DYPositionFraction(useWebMercatorProjection: Bool) -> String {
        let get2DYPositionFractionGeographicProjection = "float get2DYPositionFraction() { return get2DGeographicYPositionFraction(); }"
        let get2DYPositionFractionMercatorProjection = "float get2DYPositionFraction() { return get2DMercatorYPositionFraction(); }"
        return useWebMercatorProjection ? get2DYPositionFractionMercatorProjection : get2DYPositionFractionGeographicProjection
    }
    
    func getRenderPipeline (context context: Context, sceneMode: SceneMode, surfaceTile: GlobeSurfaceTile, numberOfDayTextures: Int, applyBrightness: Bool, applyContrast: Bool, applyHue: Bool, applySaturation: Bool, applyGamma: Bool, applyAlpha: Bool, showReflectiveOcean: Bool, showOceanWaves: Bool, enableLighting: Bool, hasVertexNormals: Bool, useWebMercatorProjection: Bool) -> RenderPipeline {
        
        let flags: Int = Int(sceneMode.rawValue) |
            (Int(applyBrightness) << 2) |
            (Int(applyContrast) << 3) |
            (Int(applyHue) << 4) |
            (Int(applySaturation) << 5) |
            (Int(applyGamma) << 6) |
            (Int(applyAlpha) << 7) |
            (Int(showReflectiveOcean) << 8) |
            (Int(showOceanWaves) << 9) |
            (Int(enableLighting) << 10) |
            (Int(hasVertexNormals) << 11) |
            (Int(useWebMercatorProjection) << 12)
        
        var surfacePipeline = surfaceTile.surfacePipeline
        if surfacePipeline != nil && surfacePipeline!.numberOfDayTextures == numberOfDayTextures && surfacePipeline!.flags == flags {
            return surfacePipeline!.pipeline
        }
        
        // New tile, or tile changed number of textures or flags.
        var pipelinesByFlags = _pipelinesByTexturesFlags[numberOfDayTextures]
        if pipelinesByFlags == nil {
            _pipelinesByTexturesFlags[numberOfDayTextures] = [Int: GlobeSurfacePipeline]()
            pipelinesByFlags = _pipelinesByTexturesFlags[numberOfDayTextures]
        }
        
        surfacePipeline = pipelinesByFlags![flags]
        if surfacePipeline == nil {
            // Cache miss - we've never seen this combination of numberOfDayTextures and flags before.
            var vs = baseVertexShaderSource
            var fs = baseFragmentShaderSource
            
            fs.defines.append("TEXTURE_UNITS \(numberOfDayTextures)")
            
            // Account for Metal not supporting sampler arrays
            if numberOfDayTextures > 0 {
                var textureArrayDefines = "\n"
                for i in 0..<numberOfDayTextures {
                    textureArrayDefines += "uniform sampler2D u_dayTexture\(i);\n"
                }
                textureArrayDefines += "uniform vec4 u_dayTextureTranslationAndScale[TEXTURE_UNITS];\n\n#ifdef APPLY_ALPHA\nuniform float u_dayTextureAlpha[TEXTURE_UNITS];\n#endif\n\n#ifdef APPLY_BRIGHTNESS\nuniform float u_dayTextureBrightness[TEXTURE_UNITS];\n#endif\n\n#ifdef APPLY_CONTRAST\nuniform float u_dayTextureContrast[TEXTURE_UNITS];\n#endif\n\n#ifdef APPLY_HUE\nuniform float u_dayTextureHue[TEXTURE_UNITS];\n#endif\n\n#ifdef APPLY_SATURATION\nuniform float u_dayTextureSaturation[TEXTURE_UNITS];\n#endif\n\n#ifdef APPLY_GAMMA\nuniform float u_dayTextureOneOverGamma[TEXTURE_UNITS];\n#endif\n\nuniform vec4 u_dayTextureTexCoordsRectangle[TEXTURE_UNITS];\n\n"
                
                fs.sources.insert(textureArrayDefines, atIndex: 0)
            }
            
            if applyBrightness {
                fs.defines.append("APPLY_BRIGHTNESS")
            }
            if (applyContrast) {
                fs.defines.append("APPLY_CONTRAST")
            }
            if (applyHue) {
                fs.defines.append("APPLY_HUE")
            }
            if (applySaturation) {
                fs.defines.append("APPLY_SATURATION")
            }
            if (applyGamma) {
                fs.defines.append("APPLY_GAMMA")
            }
            if (applyAlpha) {
                fs.defines.append("APPLY_ALPHA")
            }
            if (showReflectiveOcean) {
                fs.defines.append("SHOW_REFLECTIVE_OCEAN")
                vs.defines.append("SHOW_REFLECTIVE_OCEAN")
            }
            if (showOceanWaves) {
                fs.defines.append("SHOW_OCEAN_WAVES")
            }
            
            if enableLighting {
                if hasVertexNormals {
                    vs.defines.append("ENABLE_VERTEX_LIGHTING")
                    fs.defines.append("ENABLE_VERTEX_LIGHTING")
                } else {
                    vs.defines.append("ENABLE_DAYNIGHT_SHADING")
                    fs.defines.append("ENABLE_DAYNIGHT_SHADING")
                }
            }
            
            var computeDayColor = "vec4 computeDayColor(vec4 initialColor, vec2 textureCoordinates)\n{    \nvec4 color = initialColor;\n"
            
            for i in 0..<numberOfDayTextures {
                computeDayColor += "color = sampleAndBlend(\ncolor,\nu_dayTexture\(i),\n" +
                    "textureCoordinates,\n" +
                    "u_dayTextureTexCoordsRectangle[\(i)],\n" +
                    "u_dayTextureTranslationAndScale[\(i)],\n" +
                    (applyAlpha ? "u_dayTextureAlpha[\(i)]" : "1.0") + ",\n" +
                    (applyBrightness ? "u_dayTextureBrightness[\(i)]" : "0.0") + ",\n" +
                    (applyContrast ? "u_dayTextureContrast[\(i)]" : "0.0") + ",\n" +
                    (applyHue ? "u_dayTextureHue[\(i)]" : "0.0") + ",\n" +
                    (applySaturation ? "u_dayTextureSaturation[\(i)]" : "0.0") + ",\n" +
                    (applyGamma ? "u_dayTextureOneOverGamma[\(i)]" : "0.0") + "\n" +
                ");\n"
            }
            
            computeDayColor += "return color;\n}"
            
            fs.sources.append(computeDayColor)
            
            vs.sources.append(getPositionMode(sceneMode))
            vs.sources.append(get2DYPositionFraction(useWebMercatorProjection))
            
            let pipeline = RenderPipeline.fromCache(context: context, vertexShaderSource: vs, fragmentShaderSource: fs, vertexDescriptor: vertexDescriptor)
            pipelinesByFlags![flags] = GlobeSurfacePipeline(numberOfDayTextures: numberOfDayTextures, flags: flags, pipeline: pipeline)

            surfacePipeline = pipelinesByFlags![flags]
        }
        _pipelinesByTexturesFlags[numberOfDayTextures] = pipelinesByFlags!
        surfaceTile.surfacePipeline = surfacePipeline
        return surfacePipeline!.pipeline
    }
    
    func getPickRenderPipeline(context context: Context, sceneMode: SceneMode, useWebMercatorProjection: Bool) -> RenderPipeline {
        
        let flags = sceneMode.rawValue | (Int(useWebMercatorProjection) << 2)
        var pickShader: RenderPipeline! = _pickPipelines[flags]
        if pickShader == nil {
            var vs = baseVertexShaderSource
            vs.sources.append(getPositionMode(sceneMode))
            vs.sources.append(get2DYPositionFraction(useWebMercatorProjection))
            
            // pass through fragment shader. only depth is rendered for the globe on a pick pass
            let fs = ShaderSource(sources: [
                "void main()\n" +
                    "{\n" +
                    "    gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);\n" +
                "}\n"
                ])
            
            pickShader = RenderPipeline.fromCache(
                context : context,
                vertexShaderSource : vs,
                fragmentShaderSource : fs,
                vertexDescriptor: vertexDescriptor
            )
            _pickPipelines[flags] = pickShader
        }
        
        return pickShader
    }
    
    deinit {
        // ARC should deinit shaders
    }
    
}
