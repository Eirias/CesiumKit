//
//  SkyAtmosphere.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 13/12/2015.
//  Copyright © 2015 Test Toast. All rights reserved.
//

import Foundation

/**
 * An atmosphere drawn around the limb of the provided ellipsoid.  Based on
 * {@link http://http.developer.nvidia.com/GPUGems2/gpugems2_chapter16.html|Accurate Atmospheric Scattering}
 * in GPU Gems 2.
 * <p>
 * This is only supported in 3D.  atmosphere is faded out when morphing to 2D or Columbus view.
 * </p>
 *
 * @alias SkyAtmosphere
 * @constructor
 *
 * @param {Ellipsoid} [ellipsoid=Ellipsoid.WGS84] The ellipsoid that the atmosphere is drawn around.
 *
 * @example
 * scene.skyAtmosphere = new Cesium.SkyAtmosphere();
 *
 * @see Scene.skyAtmosphere
 */
class SkyAtmosphere {
    
    /**
    * Determines if the atmosphere is shown.
    *
    * @type {Boolean}
    * @default true
    */
    var show = true
    
    /**
     * Gets the ellipsoid the atmosphere is drawn around.
     * @memberof SkyAtmosphere.prototype
     *
     * @type {Ellipsoid}
     * @readonly
     */
    private (set) var ellipsoid: Ellipsoid
    
    private let _command = DrawCommand()
    
    private var _rpSkyFromSpace: RenderPipeline? = nil
    
    private var _rpSkyFromAtmosphere: RenderPipeline? = nil
    
    init (ellipsoid: Ellipsoid = Ellipsoid.wgs84()) {
        self.ellipsoid = ellipsoid

        let map = SkyAtmosphereUniformMap()
        map.rayleighScaleDepth = 0.25
        map.fOuterRadius = Float(ellipsoid.radii.multiplyByScalar(1.025).maximumComponent())
        map.fInnerRadius = Float(ellipsoid.maximumRadius)
        _command.uniformMap = map
        _command.owner = self
    }
    
    func update (context: Context, frameState: FrameState) -> DrawCommand? {

        if !show {
            return nil
        }
        
        if frameState.mode != .Scene3D && frameState.mode != SceneMode.Morphing {
            return nil
        }
        
        // The atmosphere is only rendered during the render pass; it is not pickable, it doesn't cast shadows, etc.
        if !frameState.passes.render {
            return nil
        }
    
    
        if _command.vertexArray == nil {

            
            let geometry = EllipsoidGeometry(
                radii : ellipsoid.radii.multiplyByScalar(1.025),
                slicePartitions : 256,
                stackPartitions : 256,
                vertexFormat : VertexFormat.PositionOnly()
            ).createGeometry(context)
            
            _command.vertexArray = VertexArray(
                fromGeometry: geometry,
                context: context,
                attributeLocations: GeometryPipeline.createAttributeLocations(geometry)
            )
            //FIXME: blending
            _command.renderState = RenderState(
                device: context.device,
                cullFace: .Back
            )
            
            _rpSkyFromSpace = RenderPipeline.fromCache(
                context : context,
                vertexShaderSource : ShaderSource(
                    defines: ["SKY_FROM_SPACE"],
                    sources: [Shaders["SkyAtmosphereVS"]!]
                ),
                fragmentShaderSource : ShaderSource(
                    sources: [Shaders["SkyAtmosphereFS"]!]
                ),
                vertexDescriptor: VertexDescriptor(attributes: _command.vertexArray!.attributes),
                depthStencil: context.depthTexture/*,
                blending : BlendingState.AlphaBlend()*/

            )
            
            
            _rpSkyFromAtmosphere = RenderPipeline.fromCache(
                context : context,
                vertexShaderSource : ShaderSource(
                    defines: ["SKY_FROM_ATMOSPHERE"],
                    sources: [Shaders["SkyAtmosphereVS"]!]
                ),
                fragmentShaderSource : ShaderSource(
                    sources: [Shaders["SkyAtmosphereFS"]!]
                ),
                vertexDescriptor: VertexDescriptor(attributes: _command.vertexArray!.attributes),
                depthStencil: context.depthTexture
            )
            
        }
    
        let cameraPosition = frameState.camera!.positionWC
        let map = _command.uniformMap as! SkyAtmosphereUniformMap
        map.fCameraHeight2 = Float(cameraPosition.magnitudeSquared)
        map.fCameraHeight = sqrt(map.fCameraHeight2)
        
        if map.fCameraHeight > map.fOuterRadius {
            // Camera in space
            _command.pipeline = _rpSkyFromSpace
        } else {
            // Camera in atmosphere
            _command.pipeline = _rpSkyFromAtmosphere
        }
        
        return _command
    }

}

private class SkyAtmosphereUniformMap: UniformMap {
    
    var fCameraHeight = Float.NaN
    
    var fCameraHeight2 = Float.NaN
    
    var fOuterRadius = Float.NaN
    
    var fInnerRadius = Float.NaN
    
    var rayleighScaleDepth = Float.NaN

    private var _floatUniforms: [String: FloatUniformFunc] = [
        
        "fCameraHeight": { (map: UniformMap) -> [Float] in
            return [(map as! SkyAtmosphereUniformMap).fCameraHeight]
        },
        
        "fCameraHeight2": { (map: UniformMap) -> [Float] in
            return [(map as! SkyAtmosphereUniformMap).fCameraHeight2]
        },
        
        "fOuterRadius": { (map: UniformMap) -> [Float] in
            return [(map as! SkyAtmosphereUniformMap).fOuterRadius]
        },
        
        "fOuterRadius2": { (map: UniformMap) -> [Float] in
            let fOuterRadius = (map as! SkyAtmosphereUniformMap).fOuterRadius
            return [fOuterRadius * fOuterRadius]
        },
        
        "fInnerRadius": { (map: UniformMap) -> [Float] in
            return [(map as! SkyAtmosphereUniformMap).fInnerRadius]
        },
        
        "fScale": { (map: UniformMap) -> [Float] in
            let saMap = map as! SkyAtmosphereUniformMap
            return [1.0 / saMap.fOuterRadius - saMap.fInnerRadius]
        },
        
        "fScaleDepth": { (map: UniformMap) -> [Float] in
            return [(map as! SkyAtmosphereUniformMap).rayleighScaleDepth]
        },
        
        
        "fScaleOverScaleDepth": { (map: UniformMap) -> [Float] in
            let saMap = map as! SkyAtmosphereUniformMap
            return [(1.0 / (saMap.fOuterRadius - saMap.fInnerRadius)) / saMap.rayleighScaleDepth]
        }
        
    ]
    
    func floatUniform(name: String) -> FloatUniformFunc? {
        return _floatUniforms[name]
    }

}

