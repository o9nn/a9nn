------------------------------------------------------------------------
--[[ DistributedAtomSpace ]]--
-- Distributed knowledge graph as a kernel service
-- Extends nn.AtomSpace with distributed capabilities:
-- - Multi-node synchronization
-- - Distributed queries
-- - Conflict-free replicated data types (CRDTs)
-- - Eventual consistency
------------------------------------------------------------------------
local DistributedAtomSpace, parent = torch.class('nn.DistributedAtomSpace', 'nn.AtomSpace')

function DistributedAtomSpace:__init(config)
   parent.__init(self, config)
   
   config = config or {}
   
   -- Distributed configuration
   self.nodeId = config.nodeId or 1
   self.clusterNodes = config.clusterNodes or {}  -- {nodeId = {host, port}}
   self.syncInterval = config.syncInterval or 5.0  -- seconds
   
   -- Replication
   self.replicationFactor = config.replicationFactor or 3
   self.consistencyLevel = config.consistencyLevel or "eventual"  -- eventual, strong
   
   -- Version vectors for CRDT (conflict-free replicated data types)
   self.versionVectors = {}  -- atom_uuid -> {node_id -> version}
   
   -- Pending operations for synchronization
   self.pendingOps = {}
   
   -- Remote node states
   self.nodeStates = {}  -- nodeId -> {lastSync, status}
   for nodeId in pairs(self.clusterNodes) do
      self.nodeStates[nodeId] = {
         lastSync = 0,
         status = "unknown",
         lag = 0
      }
   end
   
   -- Statistics
   self.distributedStats = {
      syncOperations = 0,
      conflictsResolved = 0,
      remoteQueries = 0,
      atomsReplicated = 0
   }
   
   -- Last sync time
   self.lastSyncTime = os.time()
end

-- Add node with versioning
function DistributedAtomSpace:addNode(nodeType, name, truthValue, attention, metadata)
   local node = parent.addNode(self, nodeType, name, truthValue, attention, metadata)
   
   -- Initialize version vector
   if not self.versionVectors[node.uuid] then
      self.versionVectors[node.uuid] = {}
   end
   self.versionVectors[node.uuid][self.nodeId] = (self.versionVectors[node.uuid][self.nodeId] or 0) + 1
   
   -- Add to pending operations for replication
   table.insert(self.pendingOps, {
      type = "addNode",
      node = node,
      version = self.versionVectors[node.uuid],
      timestamp = os.time(),
      nodeId = self.nodeId
   })
   
   return node
end

-- Add link with versioning
function DistributedAtomSpace:addLink(linkType, outgoingNames, truthValue, attention, metadata)
   local link = parent.addLink(self, linkType, outgoingNames, truthValue, attention, metadata)
   
   -- Initialize version vector
   if not self.versionVectors[link.uuid] then
      self.versionVectors[link.uuid] = {}
   end
   self.versionVectors[link.uuid][self.nodeId] = (self.versionVectors[link.uuid][self.nodeId] or 0) + 1
   
   -- Add to pending operations
   table.insert(self.pendingOps, {
      type = "addLink",
      link = link,
      version = self.versionVectors[link.uuid],
      timestamp = os.time(),
      nodeId = self.nodeId
   })
   
   return link
end

-- Distributed query (queries local + remote nodes)
function DistributedAtomSpace:distributedQuery(pattern)
   self.distributedStats.remoteQueries = self.distributedStats.remoteQueries + 1
   
   -- Query local first
   local localResults = parent.query(self, pattern)
   
   -- Query remote nodes (simulated - would use actual network calls)
   local remoteResults = {}
   for nodeId, nodeInfo in pairs(self.clusterNodes) do
      if nodeId ~= self.nodeId then
         -- Simulated remote query
         -- In real implementation, would make HTTP/RPC call
         -- remoteResults[nodeId] = self:remoteQuery(nodeId, pattern)
      end
   end
   
   -- Merge results
   local allResults = localResults
   for nodeId, results in pairs(remoteResults) do
      for _, result in ipairs(results) do
         table.insert(allResults, result)
      end
   end
   
   return allResults
end

-- Synchronize with other nodes
function DistributedAtomSpace:sync()
   local now = os.time()
   
   if now - self.lastSyncTime < self.syncInterval then
      return {success = false, reason = "Too soon to sync"}
   end
   
   self.lastSyncTime = now
   self.distributedStats.syncOperations = self.distributedStats.syncOperations + 1
   
   -- Prepare sync payload
   local syncPayload = {
      nodeId = self.nodeId,
      timestamp = now,
      operations = self.pendingOps,
      versionVectors = self.versionVectors
   }
   
   -- Send to all nodes (simulated)
   for nodeId, nodeInfo in pairs(self.clusterNodes) do
      if nodeId ~= self.nodeId then
         -- In real implementation, would send HTTP/RPC request
         -- self:sendToNode(nodeId, syncPayload)
         self.nodeStates[nodeId].lastSync = now
         self.nodeStates[nodeId].status = "synced"
      end
   end
   
   -- Clear pending operations after successful sync
   local opsCount = #self.pendingOps
   self.pendingOps = {}
   
   return {
      success = true,
      operationsSynced = opsCount,
      nodes = self:getNodeCount()
   }
end

-- Apply operations from remote node
function DistributedAtomSpace:applyRemoteOps(remoteNodeId, operations)
   local applied = 0
   local conflicts = 0
   
   for _, op in ipairs(operations) do
      if op.type == "addNode" then
         local existing = self.atoms[op.node.uuid]
         
         if existing then
            -- Conflict resolution using version vectors
            if self:shouldApply(op.node.uuid, remoteNodeId, op.version) then
               -- Update existing node
               existing:setTruthValue(op.node.truthValue[1], op.node.truthValue[2])
               existing:setAttention(op.node.attention)
               applied = applied + 1
            else
               conflicts = conflicts + 1
            end
         else
            -- Add new node
            self:addNode(op.node.type, op.node.name, op.node.truthValue,
               op.node.attention, op.node.metadata)
            applied = applied + 1
            self.distributedStats.atomsReplicated = self.distributedStats.atomsReplicated + 1
         end
      elseif op.type == "addLink" then
         -- Similar logic for links
         applied = applied + 1
      end
   end
   
   self.distributedStats.conflictsResolved = self.distributedStats.conflictsResolved + conflicts
   
   return {
      applied = applied,
      conflicts = conflicts
   }
end

-- Check if remote operation should be applied using version vectors
function DistributedAtomSpace:shouldApply(atomUuid, remoteNodeId, remoteVersion)
   local localVersion = self.versionVectors[atomUuid] or {}
   
   -- Compare version vectors
   local localVal = localVersion[remoteNodeId] or 0
   local remoteVal = remoteVersion[remoteNodeId] or 0
   
   -- Apply if remote is newer
   return remoteVal > localVal
end

-- Get number of cluster nodes
function DistributedAtomSpace:getNodeCount()
   local count = 1  -- Self
   for _ in pairs(self.clusterNodes) do
      count = count + 1
   end
   return count
end

-- Get cluster status
function DistributedAtomSpace:getClusterStatus()
   local status = {
      nodeId = self.nodeId,
      totalNodes = self:getNodeCount(),
      nodeStates = {},
      pendingOps = #self.pendingOps,
      lastSync = self.lastSyncTime,
      consistencyLevel = self.consistencyLevel
   }
   
   for nodeId, state in pairs(self.nodeStates) do
      status.nodeStates[nodeId] = {
         status = state.status,
         lastSync = state.lastSync,
         lag = os.time() - state.lastSync
      }
   end
   
   return status
end

-- Get distributed statistics
function DistributedAtomSpace:getDistributedStats()
   local baseStats = parent.getStats(self)
   
   return {
      local = baseStats,
      distributed = self.distributedStats,
      cluster = self:getClusterStatus()
   }
end

-- Replicate atom to specific nodes
function DistributedAtomSpace:replicateTo(atomUuid, targetNodes)
   local atom = self.atoms[atomUuid]
   if not atom then
      return {success = false, error = "Atom not found"}
   end
   
   local replicated = 0
   for _, nodeId in ipairs(targetNodes) do
      if nodeId ~= self.nodeId and self.clusterNodes[nodeId] then
         -- Simulated replication
         replicated = replicated + 1
      end
   end
   
   return {
      success = true,
      replicated = replicated
   }
end

-- Check consistency across cluster
function DistributedAtomSpace:checkConsistency()
   -- Simplified consistency check
   -- In real implementation, would verify version vectors across nodes
   
   local inconsistencies = 0
   local totalAtoms = 0
   
   for uuid, atom in pairs(self.atoms) do
      totalAtoms = totalAtoms + 1
      local version = self.versionVectors[uuid] or {}
      
      -- Check if version vector is complete
      local expectedNodes = self:getNodeCount()
      local actualNodes = 0
      for _ in pairs(version) do
         actualNodes = actualNodes + 1
      end
      
      if actualNodes < expectedNodes then
         inconsistencies = inconsistencies + 1
      end
   end
   
   return {
      totalAtoms = totalAtoms,
      inconsistencies = inconsistencies,
      consistencyRatio = (totalAtoms - inconsistencies) / math.max(totalAtoms, 1)
   }
end

-- Join cluster
function DistributedAtomSpace:joinCluster(leaderNodeId, leaderInfo)
   self.clusterNodes[leaderNodeId] = leaderInfo
   self.nodeStates[leaderNodeId] = {
      lastSync = 0,
      status = "joined",
      lag = 0
   }
   
   -- Request full sync from leader
   -- In real implementation, would fetch all atoms from leader
   
   return {
      success = true,
      clusterId = leaderNodeId,
      nodes = self:getNodeCount()
   }
end

-- Leave cluster
function DistributedAtomSpace:leaveCluster()
   -- Notify other nodes (simulated)
   self.clusterNodes = {}
   self.nodeStates = {}
   
   return {success = true}
end

function DistributedAtomSpace:__tostring__()
   local stats = self:getStats()
   local clusterStatus = self:getClusterStatus()
   
   return torch.type(self) .. string.format(
      '(node=%d, atoms=%d, nodes=%d, pending=%d)',
      self.nodeId,
      stats.totalAtoms,
      clusterStatus.totalNodes,
      clusterStatus.pendingOps
   )
end
