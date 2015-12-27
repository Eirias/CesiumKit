//
//  QuantizedTerrainMeshGenerator.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 27/12/2015.
//  Copyright © 2015 Test Toast. All rights reserved.
//

import Foundation


private let maxShort = Int16.max

private let xIndex = 0
private let yIndex = 1
private let zIndex = 2
private let hIndex = 3
private let uIndex = 4
private let vIndex = 5
private let nIndex = 6

class QuantizedTerrainMeshGenerator {
    
    
    
    
    class func createVerticesFromQuantizedTerrainMesh(/*parameters, transferableObjects*/) {
        /*var quantizedVertices = parameters.quantizedVertices;
        var quantizedVertexCount = quantizedVertices.length / 3;
        var octEncodedNormals = parameters.octEncodedNormals;
        var edgeVertexCount = parameters.westIndices.length + parameters.eastIndices.length +
        parameters.southIndices.length + parameters.northIndices.length;
        var minimumHeight = parameters.minimumHeight;
        var maximumHeight = parameters.maximumHeight;
        var center = parameters.relativeToCenter;
        
        var rectangle = parameters.rectangle;
        var west = rectangle.west;
        var south = rectangle.south;
        var east = rectangle.east;
        var north = rectangle.north;
        
        var ellipsoid = Ellipsoid.clone(parameters.ellipsoid);
        
        var uBuffer = quantizedVertices.subarray(0, quantizedVertexCount);
        var vBuffer = quantizedVertices.subarray(quantizedVertexCount, 2 * quantizedVertexCount);
        var heightBuffer = quantizedVertices.subarray(quantizedVertexCount * 2, 3 * quantizedVertexCount);
        var hasVertexNormals = defined(octEncodedNormals);
        
        var vertexStride = 6;
        if (hasVertexNormals) {
        vertexStride += 1;
        }
        
        var vertexBuffer = new Float32Array(quantizedVertexCount * vertexStride + edgeVertexCount * vertexStride);
        
        for (var i = 0, bufferIndex = 0, n = 0; i < quantizedVertexCount; ++i, bufferIndex += vertexStride, n += 2) {
        var u = uBuffer[i] / maxShort;
        var v = vBuffer[i] / maxShort;
        var height = CesiumMath.lerp(minimumHeight, maximumHeight, heightBuffer[i] / maxShort);
        
        cartographicScratch.longitude = CesiumMath.lerp(west, east, u);
        cartographicScratch.latitude = CesiumMath.lerp(south, north, v);
        cartographicScratch.height = height;
        
        ellipsoid.cartographicToCartesian(cartographicScratch, cartesian3Scratch);
        
        vertexBuffer[bufferIndex + xIndex] = cartesian3Scratch.x - center.x;
        vertexBuffer[bufferIndex + yIndex] = cartesian3Scratch.y - center.y;
        vertexBuffer[bufferIndex + zIndex] = cartesian3Scratch.z - center.z;
        vertexBuffer[bufferIndex + hIndex] = height;
        vertexBuffer[bufferIndex + uIndex] = u;
        vertexBuffer[bufferIndex + vIndex] = v;
        if (hasVertexNormals) {
        toPack.x = octEncodedNormals[n];
        toPack.y = octEncodedNormals[n + 1];
        vertexBuffer[bufferIndex + nIndex] = AttributeCompression.octPackFloat(toPack);
        }
        }
        
        var edgeTriangleCount = Math.max(0, (edgeVertexCount - 4) * 2);
        var indexBufferLength = parameters.indices.length + edgeTriangleCount * 3;
        var indexBuffer = IndexDatatype.createTypedArray(quantizedVertexCount + edgeVertexCount, indexBufferLength);
        indexBuffer.set(parameters.indices, 0);
        
        // Add skirts.
        var vertexBufferIndex = quantizedVertexCount * vertexStride;
        var indexBufferIndex = parameters.indices.length;
        indexBufferIndex = addSkirt(vertexBuffer, vertexBufferIndex, indexBuffer, indexBufferIndex, parameters.westIndices, center, ellipsoid, rectangle, parameters.westSkirtHeight, true, hasVertexNormals);
        vertexBufferIndex += parameters.westIndices.length * vertexStride;
        indexBufferIndex = addSkirt(vertexBuffer, vertexBufferIndex, indexBuffer, indexBufferIndex, parameters.southIndices, center, ellipsoid, rectangle, parameters.southSkirtHeight, false, hasVertexNormals);
        vertexBufferIndex += parameters.southIndices.length * vertexStride;
        indexBufferIndex = addSkirt(vertexBuffer, vertexBufferIndex, indexBuffer, indexBufferIndex, parameters.eastIndices, center, ellipsoid, rectangle, parameters.eastSkirtHeight, false, hasVertexNormals);
        vertexBufferIndex += parameters.eastIndices.length * vertexStride;
        indexBufferIndex = addSkirt(vertexBuffer, vertexBufferIndex, indexBuffer, indexBufferIndex, parameters.northIndices, center, ellipsoid, rectangle, parameters.northSkirtHeight, true, hasVertexNormals);
        vertexBufferIndex += parameters.northIndices.length * vertexStride;
        
        transferableObjects.push(vertexBuffer.buffer, indexBuffer.buffer);
        
        return {
        vertices : vertexBuffer.buffer,
        indices : indexBuffer.buffer
        };*/
    }
    
    func addSkirt(/*vertexBuffer, vertexBufferIndex, indexBuffer, indexBufferIndex, edgeVertices, center, ellipsoid, rectangle, skirtLength, isWestOrNorthEdge, hasVertexNormals*/) {
        /*var start, end, increment;
        var vertexStride = 6;
        if (hasVertexNormals) {
        vertexStride += 1;
        }
        if (isWestOrNorthEdge) {
        start = edgeVertices.length - 1;
        end = -1;
        increment = -1;
        } else {
        start = 0;
        end = edgeVertices.length;
        increment = 1;
        }
        
        var previousIndex = -1;
        
        var vertexIndex = vertexBufferIndex / vertexStride;
        
        var north = rectangle.north;
        var south = rectangle.south;
        var east = rectangle.east;
        var west = rectangle.west;
        
        if (east < west) {
        east += CesiumMath.TWO_PI;
        }
        
        for (var i = start; i !== end; i += increment) {
        var index = edgeVertices[i];
        var offset = index * vertexStride;
        var u = vertexBuffer[offset + uIndex];
        var v = vertexBuffer[offset + vIndex];
        var h = vertexBuffer[offset + hIndex];
        
        cartographicScratch.longitude = CesiumMath.lerp(west, east, u);
        cartographicScratch.latitude = CesiumMath.lerp(south, north, v);
        cartographicScratch.height = h - skirtLength;
        
        var position = ellipsoid.cartographicToCartesian(cartographicScratch, cartesian3Scratch);
        Cartesian3.subtract(position, center, position);
        
        vertexBuffer[vertexBufferIndex++] = position.x;
        vertexBuffer[vertexBufferIndex++] = position.y;
        vertexBuffer[vertexBufferIndex++] = position.z;
        vertexBuffer[vertexBufferIndex++] = cartographicScratch.height;
        vertexBuffer[vertexBufferIndex++] = u;
        vertexBuffer[vertexBufferIndex++] = v;
        if (hasVertexNormals) {
        vertexBuffer[vertexBufferIndex++] = vertexBuffer[offset + nIndex];
        }
        
        if (previousIndex !== -1) {
        indexBuffer[indexBufferIndex++] = previousIndex;
        indexBuffer[indexBufferIndex++] = vertexIndex - 1;
        indexBuffer[indexBufferIndex++] = index;
        
        indexBuffer[indexBufferIndex++] = vertexIndex - 1;
        indexBuffer[indexBufferIndex++] = vertexIndex;
        indexBuffer[indexBufferIndex++] = index;
        }
        
        previousIndex = index;
        ++vertexIndex;
        }
        
        return indexBufferIndex;*/
    }
    
}