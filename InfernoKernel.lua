------------------------------------------------------------------------
--[[ InfernoKernel ]]--
-- Core kernel for cognitive operating system
-- Makes cognitive processing a fundamental kernel service where
-- thinking, reasoning, and intelligence emerge from the OS itself
--
-- Inspired by Plan 9 and Inferno OS, this kernel provides:
-- - Cognitive syscalls as first-class kernel operations
-- - Distributed namespace for cognitive resources
-- - Lightweight processes as cognitive units
-- - Everything-is-a-file for cognitive resources
------------------------------------------------------------------------
local InfernoKernel, parent = torch.class('nn.InfernoKernel', 'nn.Module')

function InfernoKernel:__init(config)
   parent.__init(self)
   
   config = config or {}
   
   -- Kernel identity
   self.kernelId = config.kernelId or "inferno_" .. tostring(os.time())
   self.version = "0.1.0-alpha"
   self.bootTime = os.time()
   
   -- Core cognitive subsystems
   self.atomSpace = config.atomSpace or nn.AtomSpace({
      maxAtoms = 1000000,  -- Large distributed knowledge base
      attentionDecay = 0.995
   })
   
   self.processTable = {}  -- Active cognitive processes
   self.nextPid = 1
   
   self.scheduler = nil  -- Will be set by CognitiveScheduler
   self.memoryManager = nil  -- Will be set by MemoryManager
   self.ipc = nil  -- Will be set by InfernoIPC
   
   -- Kernel namespace (everything-is-a-file)
   self.namespace = {
      ['/proc'] = {},           -- Process information
      ['/cognitive'] = {},      -- Cognitive resources
      ['/atomspace'] = self.atomSpace,  -- Knowledge graph
      ['/agents'] = {},         -- Active agents
      ['/memory'] = {},         -- Memory resources
      ['/consciousness'] = {},  -- Consciousness layers
      ['/emotion'] = {},        -- Emotional states
      ['/reservoir'] = {}       -- Reservoir computers
   }
   
   -- Syscall table (cognitive operations as system calls)
   self.syscalls = {
      think = function(...) return self:syscall_think(...) end,
      reason = function(...) return self:syscall_reason(...) end,
      feel = function(...) return self:syscall_feel(...) end,
      remember = function(...) return self:syscall_remember(...) end,
      forget = function(...) return self:syscall_forget(...) end,
      attend = function(...) return self:syscall_attend(...) end,
      spawn_agent = function(...) return self:syscall_spawn_agent(...) end,
      query_knowledge = function(...) return self:syscall_query_knowledge(...) end,
      spread_activation = function(...) return self:syscall_spread_activation(...) end,
      shift_consciousness = function(...) return self:syscall_shift_consciousness(...) end,
      allocate_cognitive = function(...) return self:syscall_allocate_cognitive(...) end,
      free_cognitive = function(...) return self:syscall_free_cognitive(...) end,
      send_thought = function(...) return self:syscall_send_thought(...) end,
      receive_thought = function(...) return self:syscall_receive_thought(...) end
   }
   
   -- Kernel statistics
   self.stats = {
      syscallCount = 0,
      processesSpawned = 0,
      thoughtsProcessed = 0,
      knowledgeQueries = 0,
      consciousnessShifts = 0,
      uptime = 0
   }
   
   -- Distributed cluster configuration
   self.cluster = {
      nodeId = config.nodeId or 1,
      nodes = config.nodes or {},  -- Other kernel nodes
      isLeader = config.isLeader or true
   }
   
   -- Boot the kernel
   self:boot()
end

-- Boot the kernel
function InfernoKernel:boot()
   print(string.format("🔥 Inferno AGI Kernel %s booting...", self.version))
   print(string.format("   Kernel ID: %s", self.kernelId))
   print(string.format("   Node ID: %d", self.cluster.nodeId))
   
   -- Initialize namespace
   self:initNamespace()
   
   -- Register cognitive syscalls
   self:registerSyscalls()
   
   print("✅ Kernel boot complete")
   print("   Cognitive syscalls: " .. self:countSyscalls())
   print("   Namespace mounts: " .. self:countNamespace())
   print("   AtomSpace capacity: " .. self.atomSpace.maxAtoms)
end

-- Initialize the namespace
function InfernoKernel:initNamespace()
   -- Create proc entries for kernel itself
   self.namespace['/proc'][self.kernelId] = {
      pid = 0,
      name = "kernel",
      state = "running",
      cognitive_type = "kernel"
   }
   
   -- Create cognitive resource entries
   self.namespace['/cognitive']['think'] = {type = "syscall", handler = self.syscalls.think}
   self.namespace['/cognitive']['reason'] = {type = "syscall", handler = self.syscalls.reason}
   self.namespace['/cognitive']['feel'] = {type = "syscall", handler = self.syscalls.feel}
end

-- Register syscalls
function InfernoKernel:registerSyscalls()
   -- Syscalls are already registered in the syscalls table
   -- This is a placeholder for future registration logic
end

-- Count syscalls
function InfernoKernel:countSyscalls()
   local count = 0
   for _ in pairs(self.syscalls) do
      count = count + 1
   end
   return count
end

-- Count namespace entries
function InfernoKernel:countNamespace()
   local count = 0
   for _ in pairs(self.namespace) do
      count = count + 1
   end
   return count
end

------------------------------------------------------------------------
-- Cognitive Syscalls (Kernel Operations)
------------------------------------------------------------------------

-- syscall: think(input) - Process thought through cognitive pipeline
function InfernoKernel:syscall_think(pid, input, context)
   self.stats.syscallCount = self.stats.syscallCount + 1
   self.stats.thoughtsProcessed = self.stats.thoughtsProcessed + 1
   
   local process = self.processTable[pid]
   if not process then
      return {error = "Invalid PID", errno = "ESRCH"}
   end
   
   -- Store thought in AtomSpace
   local thought = self.atomSpace:addNode("ConceptNode",
      "thought_" .. os.time() .. "_" .. pid,
      {0.8, 0.9},
      0.7,
      {
         input = input,
         context = context,
         timestamp = os.time(),
         pid = pid
      }
   )
   
   return {
      success = true,
      thought_id = thought.uuid,
      timestamp = os.time()
   }
end

-- syscall: reason(premise, query) - Logical reasoning
function InfernoKernel:syscall_reason(pid, premise, query)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   -- Use AtomSpace for reasoning
   local results = self.atomSpace:query({
      type = "InheritanceLink",
      outgoing = {premise, query}
   })
   
   return {
      success = true,
      results = results,
      count = #results
   }
end

-- syscall: feel(emotion, intensity) - Update emotional state
function InfernoKernel:syscall_feel(pid, emotion, intensity)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   local process = self.processTable[pid]
   if not process then
      return {error = "Invalid PID", errno = "ESRCH"}
   end
   
   -- Update process emotion
   process.emotion = {
      type = emotion,
      intensity = intensity,
      timestamp = os.time()
   }
   
   -- Store in namespace
   self.namespace['/emotion'][tostring(pid)] = process.emotion
   
   return {success = true}
end

-- syscall: remember(key, value, importance) - Store memory
function InfernoKernel:syscall_remember(pid, key, value, importance)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   importance = importance or 0.5
   
   local memory = self.atomSpace:addNode("ConceptNode",
      key,
      {importance, 0.9},
      importance,
      {
         value = value,
         pid = pid,
         timestamp = os.time()
      }
   )
   
   return {
      success = true,
      memory_id = memory.uuid
   }
end

-- syscall: forget(key, threshold) - Decay/remove memory
function InfernoKernel:syscall_forget(pid, key, threshold)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   local node = self.atomSpace:getNode("ConceptNode", key)
   if node then
      threshold = threshold or 0.1
      if node.attention < threshold then
         -- Mark node as forgotten by setting attention to 0
         node:setAttention(0.0)
         return {success = true, forgotten = true}
      else
         -- Just decay attention
         node:setAttention(node.attention * 0.5)
         return {success = true, forgotten = false, attention = node.attention}
      end
   end
   
   return {success = false, error = "Key not found"}
end

-- syscall: attend(target, spreadFactor) - Focus attention
function InfernoKernel:syscall_attend(pid, target, spreadFactor)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   local node = self.atomSpace:getNode("ConceptNode", target)
   if node then
      node:setAttention(1.0)  -- Maximum attention
      self.atomSpace:spreadAttention(node.uuid, spreadFactor or 0.7, 2)
      return {success = true}
   end
   
   return {success = false, error = "Target not found"}
end

-- syscall: spawn_agent(config) - Create new cognitive agent process
function InfernoKernel:syscall_spawn_agent(pid, agentConfig)
   self.stats.syscallCount = self.stats.syscallCount + 1
   self.stats.processesSpawned = self.stats.processesSpawned + 1
   
   local newPid = self.nextPid
   self.nextPid = self.nextPid + 1
   
   -- Create cognitive process (will be full CognitiveProcess later)
   local process = {
      pid = newPid,
      ppid = pid,  -- Parent PID
      name = agentConfig.name or ("agent_" .. newPid),
      role = agentConfig.role or "worker",
      state = "running",
      created = os.time(),
      emotion = {type = "neutral", intensity = 0.5},
      cognitive_type = "agent"
   }
   
   self.processTable[newPid] = process
   
   -- Add to namespace
   self.namespace['/proc'][tostring(newPid)] = process
   self.namespace['/agents'][tostring(newPid)] = {
      pid = newPid,
      config = agentConfig
   }
   
   return {
      success = true,
      pid = newPid,
      process = process
   }
end

-- syscall: query_knowledge(pattern) - Query distributed knowledge graph
function InfernoKernel:syscall_query_knowledge(pid, pattern)
   self.stats.syscallCount = self.stats.syscallCount + 1
   self.stats.knowledgeQueries = self.stats.knowledgeQueries + 1
   
   local results = self.atomSpace:query(pattern)
   
   return {
      success = true,
      results = results,
      count = #results,
      local_node = self.cluster.nodeId
   }
end

-- syscall: spread_activation(source, strength) - Spread activation in knowledge graph
function InfernoKernel:syscall_spread_activation(pid, source, strength)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   local node = self.atomSpace:getNode("ConceptNode", source)
   if node then
      self.atomSpace:spreadAttention(node.uuid, strength or 0.6, 3)
      return {success = true}
   end
   
   return {success = false, error = "Source not found"}
end

-- syscall: shift_consciousness(target_layer) - Change consciousness level
function InfernoKernel:syscall_shift_consciousness(pid, targetLayer)
   self.stats.syscallCount = self.stats.syscallCount + 1
   self.stats.consciousnessShifts = self.stats.consciousnessShifts + 1
   
   local process = self.processTable[pid]
   if not process then
      return {error = "Invalid PID", errno = "ESRCH"}
   end
   
   process.consciousness_layer = targetLayer
   
   -- Update namespace
   self.namespace['/consciousness'][tostring(pid)] = {
      layer = targetLayer,
      timestamp = os.time()
   }
   
   return {success = true, layer = targetLayer}
end

-- syscall: allocate_cognitive(size, type) - Allocate cognitive resource
function InfernoKernel:syscall_allocate_cognitive(pid, size, resourceType)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   -- Simplified allocation (will be handled by MemoryManager)
   local resourceId = "resource_" .. os.time() .. "_" .. torch.random(1, 999999)
   
   self.namespace['/memory'][resourceId] = {
      pid = pid,
      size = size,
      type = resourceType or "tensor",
      allocated = os.time()
   }
   
   return {
      success = true,
      resource_id = resourceId
   }
end

-- syscall: free_cognitive(resource_id) - Free cognitive resource
function InfernoKernel:syscall_free_cognitive(pid, resourceId)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   if self.namespace['/memory'][resourceId] then
      self.namespace['/memory'][resourceId] = nil
      return {success = true}
   end
   
   return {success = false, error = "Resource not found"}
end

-- syscall: send_thought(target_pid, thought) - IPC for cognitive processes
function InfernoKernel:syscall_send_thought(pid, targetPid, thought)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   local targetProcess = self.processTable[targetPid]
   if not targetProcess then
      return {error = "Target PID not found", errno = "ESRCH"}
   end
   
   -- Initialize message queue if needed
   targetProcess.messageQueue = targetProcess.messageQueue or {}
   
   table.insert(targetProcess.messageQueue, {
      from = pid,
      thought = thought,
      timestamp = os.time()
   })
   
   return {success = true, delivered = true}
end

-- syscall: receive_thought(blocking) - Receive thought from message queue
function InfernoKernel:syscall_receive_thought(pid, blocking)
   self.stats.syscallCount = self.stats.syscallCount + 1
   
   local process = self.processTable[pid]
   if not process then
      return {error = "Invalid PID", errno = "ESRCH"}
   end
   
   process.messageQueue = process.messageQueue or {}
   
   if #process.messageQueue > 0 then
      local message = table.remove(process.messageQueue, 1)
      return {
         success = true,
         message = message
      }
   end
   
   return {
      success = true,
      message = nil
   }
end

------------------------------------------------------------------------
-- Kernel Management
------------------------------------------------------------------------

-- Get process by PID
function InfernoKernel:getProcess(pid)
   return self.processTable[pid]
end

-- Kill process
function InfernoKernel:kill(pid)
   local process = self.processTable[pid]
   if process then
      process.state = "terminated"
      
      -- Clean up namespace
      self.namespace['/proc'][tostring(pid)] = nil
      self.namespace['/agents'][tostring(pid)] = nil
      self.namespace['/emotion'][tostring(pid)] = nil
      self.namespace['/consciousness'][tostring(pid)] = nil
      
      self.processTable[pid] = nil
      return true
   end
   return false
end

-- List all processes
function InfernoKernel:ps()
   local processes = {}
   for pid, proc in pairs(self.processTable) do
      table.insert(processes, {
         pid = pid,
         name = proc.name,
         state = proc.state,
         cognitive_type = proc.cognitive_type
      })
   end
   return processes
end

-- Get kernel statistics
function InfernoKernel:getStats()
   self.stats.uptime = os.time() - self.bootTime
   self.stats.activeProcesses = 0
   for _ in pairs(self.processTable) do
      self.stats.activeProcesses = self.stats.activeProcesses + 1
   end
   self.stats.atomSpaceStats = self.atomSpace:getStats()
   return self.stats
end

-- Access namespace (file-like interface)
function InfernoKernel:open(path)
   -- Navigate namespace
   local parts = {}
   for part in string.gmatch(path, "[^/]+") do
      table.insert(parts, part)
   end
   
   local current = self.namespace
   for _, part in ipairs(parts) do
      if current[part] or current['/' .. part] then
         current = current[part] or current['/' .. part]
      else
         return nil, "Path not found: " .. path
      end
   end
   
   return current
end

-- Shutdown kernel
function InfernoKernel:shutdown()
   print("🔥 Inferno AGI Kernel shutting down...")
   
   -- Kill all processes
   local pids = {}
   for pid in pairs(self.processTable) do
      table.insert(pids, pid)
   end
   for _, pid in ipairs(pids) do
      self:kill(pid)
   end
   
   -- Save AtomSpace
   print("   Saving AtomSpace...")
   -- self.atomSpace:save("inferno_atomspace.t7")
   
   print("✅ Kernel shutdown complete")
   print(string.format("   Uptime: %d seconds", os.time() - self.bootTime))
   print(string.format("   Syscalls processed: %d", self.stats.syscallCount))
   print(string.format("   Thoughts processed: %d", self.stats.thoughtsProcessed))
end

function InfernoKernel:__tostring__()
   local stats = self:getStats()
   return string.format(
      'nn.InfernoKernel(v%s, node=%d, processes=%d, syscalls=%d, uptime=%ds)',
      self.version,
      self.cluster.nodeId,
      stats.activeProcesses,
      stats.syscallCount,
      stats.uptime
   )
end
