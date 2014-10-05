//
//  QuadTreePrimitive.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 16/08/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

/**
* Renders massive sets of data by utilizing level-of-detail and culling.  The globe surface is divided into
* a quadtree of tiles with large, low-detail tiles at the root and small, high-detail tiles at the leaves.
* The set of tiles to render is selected by projecting an estimate of the geometric error in a tile onto
* the screen to estimate screen-space error, in pixels, which must be below a user-specified threshold.
* The actual content of the tiles is arbitrary and is specified using a {@link QuadtreeTileProvider}.
*
* @alias QuadtreePrimitive
* @constructor
* @private
*
* @param {QuadtreeTileProvider} options.tileProvider The tile provider that loads, renders, and estimates
*        the distance to individual tiles.
* @param {Number} [options.maximumScreenSpaceError=2] The maximum screen-space error, in pixels, that is allowed.
*        A higher maximum error will render fewer tiles and improve performance, while a lower
*        value will improve visual quality.
* @param {Number} [options.tileCacheSize=100] The maximum number of tiles that will be retained in the tile cache.
*        Note that tiles will never be unloaded if they were used for rendering the last
*        frame, so the actual number of resident tiles may be higher.  The value of
*        this property will not affect visual quality.
*/

class QuadtreePrimitive {
    
    var tileProvider: QuadtreeTileProvider
    
    var debug = (
        enableDebugOutput : false,
        
        maxDepth: 0,
        tilesVisited: 0,
        tilesCulled: 0,
        tilesRendered: 0,
        tilesWaitingForChildren: 0,
        
        lastMaxDepth: -1,
        lastTilesVisited: -1,
        lastTilesCulled: -1,
        lastTilesRendered: -1,
        lastTilesWaitingForChildren: -1,
        
        suspendLodUpdate: false
    )
    
    private var _tilesToRender = [QuadtreeTile]()
    
    private var _tileTraversalQueue = Queue<QuadtreeTile>()
    
    private var _tileLoadQueue = [QuadtreeTile]()
    
    private var _tileReplacementQueue = TileReplacementQueue()
    
    private var _levelZeroTiles = [QuadtreeTile]()
    private var _levelZeroTilesReady = false
    
    /**
    * Gets or sets the maximum screen-space error, in pixels, that is allowed.
    * A higher maximum error will render fewer tiles and improve performance, while a lower
    * value will improve visual quality.
    * @type {Number}
    * @default 2
    */
    var maximumScreenSpaceError: Int
    
    /**
    * Gets or sets the maximum number of tiles that will be retained in the tile cache.
    * Note that tiles will never be unloaded if they were used for rendering the last
    * frame, so the actual number of resident tiles may be higher.  The value of
    * this property will not affect visual quality.
    * @type {Number}
    * @default 100
    */
    var tileCacheSize: Int
    
    var _occluders: QuadtreeOccluders

    init (tileProvider: QuadtreeTileProvider, maximumScreenSpaceError: Int = 2, tileCacheSize: Int = 100) {
        
        self.maximumScreenSpaceError = maximumScreenSpaceError
        self.tileCacheSize = tileCacheSize
        
        assert(tileProvider.quadtree == nil, "A QuadtreeTileProvider can only be used with a single QuadtreePrimitive")
        
        self.tileProvider = tileProvider
        
        var tilingScheme = tileProvider.tilingScheme
        var ellipsoid = tilingScheme.ellipsoid
        
        _occluders = QuadtreeOccluders(ellipsoid : ellipsoid)
        
        self.tileCacheSize = tileCacheSize
        
        self.tileProvider.quadtree = self
    }
    
    /**
    * Invalidates and frees all the tiles in the quadtree.  The tiles must be reloaded
    * before they can be displayed.
    *
    * @memberof QuadtreePrimitive
    */
        
    func invalidateAllTiles() {
        // Clear the replacement queue
        _tileReplacementQueue.head = nil
        _tileReplacementQueue.tail = nil
        _tileReplacementQueue.count = 0
        
        // Free and recreate the level zero tiles.
        for tile in _levelZeroTiles {
            tile.freeResources()
        }
        _levelZeroTiles.removeAll()
    }
    /**
    * Invokes a specified function for each {@link QuadtreeTile} that is partially
    * or completely loaded.
    *
    * @param {Function} tileFunction The function to invoke for each loaded tile.  The
    *        function is passed a reference to the tile as its only parameter.
    */
    
    func forEachLoadedTile (tileFunction: QuadtreeTile -> ()) {
        var tile = _tileReplacementQueue.head
        while tile != nil {
            if tile!.state != .Start {
                tileFunction(tile!)
            }
            tile = tile!.replacementNext
        }
    }
    
    /**
    * Invokes a specified function for each {@link QuadtreeTile} that was rendered
    * in the most recent frame.
    *
    * @param {Function} tileFunction The function to invoke for each rendered tile.  The
    *        function is passed a reference to the tile as its only parameter.
    */
    /*QuadtreePrimitive.prototype.forEachRenderedTile = function(tileFunction) {
    var tilesRendered = this._tilesToRender;
    for (var i = 0, len = tilesRendered.length; i < len; ++i) {
    tileFunction(tilesRendered[i]);
    }
    }*/
    
    /**
    * Updates the primitive.
    *
    * @param {Context} context The rendering context to use.
    * @param {FrameState} frameState The state of the current frame.
    * @param {DrawCommand[]} commandList The list of draw commands.  The primitive will usually add
    *        commands to this array during the update call.
    */
    func update (#context: Context, frameState: FrameState, inout commandList: [Command]) {
  
        tileProvider.beginUpdate(context: context, frameState: frameState, commandList: commandList)
        
        selectTilesForRendering(context: context, frameState: frameState)
        //processTileLoadQueue(context, frameState)
        //createRenderCommandsForSelectedTiles(context, frameState, commandList)
        
        //this._tileProvider.endUpdate(context, frameState, commandList);*/
    }
    
    /*
    /**
    * Returns true if this object was destroyed; otherwise, false.
    * <br /><br />
    * If this object was destroyed, it should not be used; calling any function other than
    * <code>isDestroyed</code> will result in a {@link DeveloperError} exception.
    *
    * @memberof QuadtreePrimitive
    *
    * @returns {Boolean} True if this object was destroyed; otherwise, false.
    *
    * @see QuadtreePrimitive#destroy
    */
    QuadtreePrimitive.prototype.isDestroyed = function() {
    return false;
    };
    
    /**
    * Destroys the WebGL resources held by this object.  Destroying an object allows for deterministic
    * release of WebGL resources, instead of relying on the garbage collector to destroy this object.
    * <br /><br />
    * Once an object is destroyed, it should not be used; calling any function other than
    * <code>isDestroyed</code> will result in a {@link DeveloperError} exception.  Therefore,
    * assign the return value (<code>undefined</code>) to the object as done in the example.
    *
    * @memberof QuadtreePrimitive
    *
    * @returns {undefined}
    *
    * @exception {DeveloperError} This object was destroyed, i.e., destroy() was called.
    *
    * @see QuadtreePrimitive#isDestroyed
    *
    * @example
    * primitive = primitive && primitive.destroy();
    */
    QuadtreePrimitive.prototype.destroy = function() {
    this._tileProvider = this._tileProvider && this._tileProvider.destroy();
    };
    */
    func selectTilesForRendering(#context: Context, frameState: FrameState) {
        
        if (debug.suspendLodUpdate) {
            return
        }
        
        var i: Int
        var len: Int
        /*
        // Clear the render list.
        var tilesToRender = primitive._tilesToRender;
        tilesToRender.length = 0;
        
        var traversalQueue = primitive._tileTraversalQueue;
        traversalQueue.clear();
        
        debug.maxDepth = 0;
        debug.tilesVisited = 0;
        debug.tilesCulled = 0;
        debug.tilesRendered = 0;
        debug.tilesWaitingForChildren = 0;
        
        primitive._tileLoadQueue.length = 0;
        primitive._tileReplacementQueue.markStartOfRenderFrame();
        
        // We can't render anything before the level zero tiles exist.
        if (!defined(primitive._levelZeroTiles)) {
            if (primitive._tileProvider.ready) {
                var terrainTilingScheme = primitive._tileProvider.tilingScheme;
                primitive._levelZeroTiles = QuadtreeTile.createLevelZeroTiles(terrainTilingScheme);
            } else {
                // Nothing to do until the provider is ready.
                return;
            }
        }
        
        primitive._occluders.ellipsoid.cameraPosition = frameState.camera.positionWC;
        
        var tileProvider = primitive._tileProvider;
        var occluders = primitive._occluders;
        
        var tile;
        
        // Enqueue the root tiles that are renderable and visible.
        var levelZeroTiles = primitive._levelZeroTiles;
        for (i = 0, len = levelZeroTiles.length; i < len; ++i) {
            tile = levelZeroTiles[i];
            primitive._tileReplacementQueue.markTileRendered(tile);
            if (tile.needsLoading) {
                queueTileLoad(primitive, tile);
            }
            if (tile.renderable && tileProvider.computeTileVisibility(tile, frameState, occluders) !== Visibility.NONE) {
                traversalQueue.enqueue(tile);
            } else {
                ++debug.tilesCulled;
                if (!tile.renderable) {
                    ++debug.tilesWaitingForChildren;
                }
            }
        }
        
        // Traverse the tiles in breadth-first order.
        // This ordering allows us to load bigger, lower-detail tiles before smaller, higher-detail ones.
        // This maximizes the average detail across the scene and results in fewer sharp transitions
        // between very different LODs.
        while (defined((tile = traversalQueue.dequeue()))) {
            ++debug.tilesVisited;
            
            primitive._tileReplacementQueue.markTileRendered(tile);
            
            if (tile.level > debug.maxDepth) {
                debug.maxDepth = tile.level;
            }
            
            // There are a few different algorithms we could use here.
            // This one doesn't load children unless we refine to them.
            // We may want to revisit this in the future.
            
            if (screenSpaceError(primitive, context, frameState, tile) < primitive.maximumScreenSpaceError) {
                // This tile meets SSE requirements, so render it.
                addTileToRenderList(primitive, tile);
            } else if (queueChildrenLoadAndDetermineIfChildrenAreAllRenderable(primitive, tile)) {
                // SSE is not good enough and children are loaded, so refine.
                var children = tile.children;
                // PERFORMANCE_IDEA: traverse children front-to-back so we can avoid sorting by distance later.
                for (i = 0, len = children.length; i < len; ++i) {
                    if (tileProvider.computeTileVisibility(children[i], frameState, occluders) !== Visibility.NONE) {
                        traversalQueue.enqueue(children[i]);
                    } else {
                        ++debug.tilesCulled;
                    }
                }
            } else {
                ++debug.tilesWaitingForChildren;
                // SSE is not good enough but not all children are loaded, so render this tile anyway.
                addTileToRenderList(primitive, tile);
            }
        }
        
        if (debug.enableDebugOutput) {
            if (debug.tilesVisited !== debug.lastTilesVisited ||
                debug.tilesRendered !== debug.lastTilesRendered ||
                debug.tilesCulled !== debug.lastTilesCulled ||
                debug.maxDepth !== debug.lastMaxDepth ||
                debug.tilesWaitingForChildren !== debug.lastTilesWaitingForChildren) {
                    
                    /*global console*/
                    console.log('Visited ' + debug.tilesVisited + ', Rendered: ' + debug.tilesRendered + ', Culled: ' + debug.tilesCulled + ', Max Depth: ' + debug.maxDepth + ', Waiting for children: ' + debug.tilesWaitingForChildren);
                    
                    debug.lastTilesVisited = debug.tilesVisited;
                    debug.lastTilesRendered = debug.tilesRendered;
                    debug.lastTilesCulled = debug.tilesCulled;
                    debug.lastMaxDepth = debug.maxDepth;
                    debug.lastTilesWaitingForChildren = debug.tilesWaitingForChildren;
            }
        }
    }
    
    function screenSpaceError(primitive, context, frameState, tile) {
    if (frameState.mode === SceneMode.SCENE2D) {
    return screenSpaceError2D(primitive, context, frameState, tile);
    }
    
    var maxGeometricError = primitive._tileProvider.getLevelMaximumGeometricError(tile.level);
    
    var distance = primitive._tileProvider.computeDistanceToTile(tile, frameState);
    tile._distance = distance;
    
    var height = context.drawingBufferHeight;
    
    var camera = frameState.camera;
    var frustum = camera.frustum;
    var fovy = frustum.fovy;
    
    // PERFORMANCE_IDEA: factor out stuff that's constant across tiles.
    return (maxGeometricError * height) / (2 * distance * Math.tan(0.5 * fovy));
    }
    
    function screenSpaceError2D(primitive, context, frameState, tile) {
    var camera = frameState.camera;
    var frustum = camera.frustum;
    var width = context.drawingBufferWidth;
    var height = context.drawingBufferHeight;
    
    var maxGeometricError = primitive._tileProvider.getLevelMaximumGeometricError(tile.level);
    var pixelSize = Math.max(frustum.top - frustum.bottom, frustum.right - frustum.left) / Math.max(width, height);
    return maxGeometricError / pixelSize;
    }
    
    function addTileToRenderList(primitive, tile) {
    primitive._tilesToRender.push(tile);
    ++primitive._debug.tilesRendered;
    }
    
    function queueChildrenLoadAndDetermineIfChildrenAreAllRenderable(primitive, tile) {
    var allRenderable = true;
    var allUpsampledOnly = true;
    
    var children = tile.children;
    for (var i = 0, len = children.length; i < len; ++i) {
    var child = children[i];
    
    primitive._tileReplacementQueue.markTileRendered(child);
    
    allUpsampledOnly = allUpsampledOnly && child.upsampledFromParent;
    allRenderable = allRenderable && child.renderable;
    
    if (child.needsLoading) {
    queueTileLoad(primitive, child);
    }
    }
    
    if (!allRenderable) {
    ++primitive._debug.tilesWaitingForChildren;
    }
    
    // If all children are upsampled from this tile, we just render this tile instead of its children.
    return allRenderable && !allUpsampledOnly;
    }
    
    function queueTileLoad(primitive, tile) {
    primitive._tileLoadQueue.push(tile);
    }
    
    function processTileLoadQueue(primitive, context, frameState) {
    var tileLoadQueue = primitive._tileLoadQueue;
    var tileProvider = primitive._tileProvider;
    
    if (tileLoadQueue.length === 0) {
    return;
    }
    
    // Remove any tiles that were not used this frame beyond the number
    // we're allowed to keep.
    primitive._tileReplacementQueue.trimTiles(primitive.tileCacheSize);
    
    var startTime = getTimestamp();
    var timeSlice = primitive._loadQueueTimeSlice;
    var endTime = startTime + timeSlice;
    
    for (var len = tileLoadQueue.length - 1, i = len; i >= 0; --i) {
    var tile = tileLoadQueue[i];
    primitive._tileReplacementQueue.markTileRendered(tile);
    tileProvider.loadTile(context, frameState, tile);
    if (getTimestamp() >= endTime) {
    break;
    }
    }
    }
    
    function createRenderCommandsForSelectedTiles(primitive, context, frameState, commandList) {
    function tileDistanceSortFunction(a, b) {
    return a._distance - b._distance;
    }
    
    var tileProvider = primitive._tileProvider;
    var tilesToRender = primitive._tilesToRender;
    
    tilesToRender.sort(tileDistanceSortFunction);
    
    for (var i = 0, len = tilesToRender.length; i < len; ++i) {
    tileProvider.showTileThisFrame(tilesToRender[i], context, frameState, commandList);
    }*/
    }

}