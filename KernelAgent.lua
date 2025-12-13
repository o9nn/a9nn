------------------------------------------------------------------------
--[[ KernelAgent ]]--
-- Agents as first-class kernel citizens
-- Integrates CognitiveAgent with InfernoKernel as processes
-- Provides unified interface between agent architecture and kernel services
------------------------------------------------------------------------
local KernelAgent, parent = torch.class('nn.KernelAgent', 'nn.CognitiveAgent')

function KernelAgent:__init(kernel, config)
   config = config or {}
   
   -- Store kernel reference
   self.kernel = kernel
   
   -- Initialize parent CognitiveAgent
   parent.__init(self, config)
   
   -- Register as a kernel process
   local spawnResult = kernel.syscalls.spawn_agent(0, {
      name = self.name,
      role = self.role,
      cognitiveType = "kernel_agent"
   })
   
   if spawnResult.success then
      self.pid = spawnResult.pid
      self.process = nn.CognitiveProcess(kernel, {
         pid = self.pid,
         name = self.name,
         role = self.role,
         personality = self.personality,
         cognitiveType = "kernel_agent"
      })
      
      -- Store in kernel process table
      kernel.processTable[self.pid] = self.process
   else
      error("Failed to register agent as kernel process")
   end
   
   -- Bind syscall methods
   self:bindSyscalls()
end

-- Bind syscall methods for easy access
function KernelAgent:bindSyscalls()
   -- Create convenient wrappers for syscalls
   self.syscall = function(name, ...)
      return self.process:syscall(name, ...)
   end
end

-- Override executeTask to use kernel syscalls
function KernelAgent:executeTask(task)
   -- Use kernel's cognitive syscalls
   local result = parent.executeTask(self, task)
   
   -- Process through kernel
   if task.type == "think" then
      local thinkResult = self.syscall("think", task.input, task.context)
      result.kernelResult = thinkResult
   elseif task.type == "reason" then
      local reasonResult = self.syscall("reason", task.premise, task.query)
      result.kernelResult = reasonResult
   elseif task.type == "query" then
      local queryResult = self.syscall("query_knowledge", task.pattern)
      result.kernelResult = queryResult
   end
   
   return result
end

-- Override spawnSubordinate to create kernel-aware subordinates
function KernelAgent:spawnSubordinate(config)
   -- Create subordinate as kernel agent
   local subConfig = config or {}
   subConfig.kernel = self.kernel
   
   local subordinate = nn.KernelAgent(self.kernel, subConfig)
   subordinate.parent = self
   
   table.insert(self.subordinates, subordinate)
   
   -- Create inheritance link in kernel's AtomSpace
   self.kernel.atomSpace:addLink("InheritanceLink",
      {subordinate.id, self.id},
      {0.95, 0.9}
   )
   
   return subordinate
end

-- Think using kernel syscall
function KernelAgent:think(input, context)
   return self.syscall("think", input, context)
end

-- Reason using kernel syscall
function KernelAgent:reason(premise, query)
   return self.syscall("reason", premise, query)
end

-- Feel using kernel syscall
function KernelAgent:feel(emotion, intensity)
   local result = self.syscall("feel", emotion, intensity)
   
   -- Update local emotion state
   if result.success then
      self.personality.emotionalState = {
         type = emotion,
         intensity = intensity,
         timestamp = os.time()
      }
   end
   
   return result
end

-- Remember using kernel syscall
function KernelAgent:remember(key, value, importance)
   return self.syscall("remember", key, value, importance)
end

-- Query knowledge using kernel syscall
function KernelAgent:queryKnowledge(pattern)
   return self.syscall("query_knowledge", pattern)
end

-- Spread activation in kernel's AtomSpace
function KernelAgent:spreadActivation(source, strength)
   return self.syscall("spread_activation", source, strength)
end

-- Shift consciousness level
function KernelAgent:shiftConsciousness(level)
   local result = self.syscall("shift_consciousness", level)
   
   if result.success and self.process then
      self.process.consciousnessLevel = level
   end
   
   return result
end

-- Send thought to another agent
function KernelAgent:sendThought(targetPid, thought)
   return self.syscall("send_thought", targetPid, thought)
end

-- Receive thought from message queue
function KernelAgent:receiveThought(blocking)
   return self.syscall("receive_thought", blocking)
end

-- Process cognitive cycle
function KernelAgent:cycle()
   if not self.process then
      return nil
   end
   
   -- Execute process cycle
   local result = self.process:cycle()
   
   -- Process any queued tasks
   if #self.taskQueue > 0 then
      self:processQueue()
   end
   
   return result
end

-- Get comprehensive status including kernel info
function KernelAgent:getStatus()
   local agentStatus = parent.getStatus(self)
   
   -- Add kernel-specific information
   agentStatus.kernel = {
      pid = self.pid,
      processState = self.process and self.process.state or "unknown",
      syscallsMade = self.process and self.process.stats.syscallsMade or 0,
      messageQueueSize = self.process and #self.process.messageQueue or 0
   }
   
   return agentStatus
end

-- Override delegate to use kernel IPC
function KernelAgent:delegate(task, subordinateId)
   local targetId = parent.delegate(self, task, subordinateId)
   
   -- Send via kernel IPC
   if targetId then
      for _, sub in ipairs(self.subordinates) do
         if sub.id == targetId and sub.pid then
            self.sendThought(sub.pid, {
               type = "delegated_task",
               task = task
            })
         end
      end
   end
   
   return targetId
end

-- Shutdown agent and clean up kernel resources
function KernelAgent:shutdown()
   -- Terminate all subordinates
   for _, sub in ipairs(self.subordinates) do
      if sub.shutdown then
         sub:shutdown()
      end
   end
   
   -- Terminate process
   if self.process then
      self.process:terminate()
   end
   
   -- Remove from kernel
   if self.kernel and self.pid then
      self.kernel:kill(self.pid)
   end
   
   print(string.format("🛑 KernelAgent %s (PID %d) shutdown", self.name, self.pid))
end

function KernelAgent:__tostring__()
   return string.format(
      'nn.KernelAgent(pid=%d, name=%s, role=%s, subordinates=%d, consciousness=L%d)',
      self.pid or 0,
      self.name,
      self.role,
      #self.subordinates,
      self.process and self.process.consciousnessLevel or 1
   )
end
