------------------------------------------------------------------------
--[[ CognitiveProcess ]]--
-- Processes as cognitive units in the Inferno kernel
-- Each process is an independent cognitive entity with:
-- - Personality traits
-- - Emotional state
-- - Working memory
-- - Attention focus
-- - Consciousness level
------------------------------------------------------------------------
local CognitiveProcess = torch.class('nn.CognitiveProcess')

function CognitiveProcess:__init(kernel, config)
   config = config or {}
   
   self.kernel = kernel
   self.pid = config.pid
   self.ppid = config.ppid or 0  -- Parent PID
   self.name = config.name or ("process_" .. self.pid)
   self.role = config.role or "worker"
   
   -- State
   self.state = "ready"  -- ready, running, blocked, terminated
   self.created = os.time()
   self.lastScheduled = 0
   self.cpuTime = 0
   
   -- Cognitive attributes
   self.personality = config.personality or nn.Personality({
      intelligence = 0.7,
      creativity = 0.6,
      empathy = 0.5
   })
   
   self.emotion = {
      type = "neutral",
      intensity = 0.5,
      valence = 0.0,
      arousal = 0.5
   }
   
   self.consciousnessLevel = config.consciousnessLevel or 1
   
   -- Working memory (process-local)
   self.workingMemory = {}
   self.attentionFocus = nil
   
   -- Message queue
   self.messageQueue = {}
   
   -- Cognitive type
   self.cognitiveType = config.cognitiveType or "generic"
   
   -- Priority
   self.priority = config.priority or 5  -- 0 (highest) to 10 (lowest)
   
   -- Statistics
   self.stats = {
      syscallsMade = 0,
      thoughtsProcessed = 0,
      messagesReceived = 0,
      messagesSent = 0
   }
end

-- Execute a cognitive cycle
function CognitiveProcess:cycle()
   if self.state ~= "running" then
      return nil
   end
   
   -- Perform cognitive operations via syscalls
   local result = {
      processed = true,
      timestamp = os.time()
   }
   
   -- Process any incoming messages
   self:processMessages()
   
   -- Update emotional state
   self:updateEmotion()
   
   -- Decay working memory
   self:decayWorkingMemory()
   
   return result
end

-- Process incoming messages
function CognitiveProcess:processMessages()
   while #self.messageQueue > 0 do
      local msg = table.remove(self.messageQueue, 1)
      self.stats.messagesReceived = self.stats.messagesReceived + 1
      
      -- Store in working memory
      table.insert(self.workingMemory, {
         type = "message",
         from = msg.from,
         content = msg.thought,
         timestamp = msg.timestamp
      })
   end
end

-- Update emotional state
function CognitiveProcess:updateEmotion()
   -- Emotional decay towards neutral
   if self.emotion.intensity > 0.3 then
      self.emotion.intensity = self.emotion.intensity * 0.98
   end
   
   if math.abs(self.emotion.valence) > 0.1 then
      self.emotion.valence = self.emotion.valence * 0.95
   end
end

-- Decay working memory
function CognitiveProcess:decayWorkingMemory()
   -- Remove old items from working memory
   local cutoff = os.time() - 300  -- 5 minutes
   local newMemory = {}
   
   for _, item in ipairs(self.workingMemory) do
      if item.timestamp > cutoff then
         table.insert(newMemory, item)
      end
   end
   
   self.workingMemory = newMemory
end

-- Make a syscall to the kernel
function CognitiveProcess:syscall(name, ...)
   if not self.kernel or not self.kernel.syscalls[name] then
      return {error = "Syscall not found: " .. name, errno = "ENOSYS"}
   end
   
   self.stats.syscallsMade = self.stats.syscallsMade + 1
   return self.kernel.syscalls[name](self.pid, ...)
end

-- Think (high-level cognitive operation)
function CognitiveProcess:think(input, context)
   self.stats.thoughtsProcessed = self.stats.thoughtsProcessed + 1
   return self:syscall("think", input, context)
end

-- Reason
function CognitiveProcess:reason(premise, query)
   return self:syscall("reason", premise, query)
end

-- Feel
function CognitiveProcess:feel(emotion, intensity)
   self.emotion.type = emotion
   self.emotion.intensity = intensity
   return self:syscall("feel", emotion, intensity)
end

-- Remember
function CognitiveProcess:remember(key, value, importance)
   return self:syscall("remember", key, value, importance)
end

-- Forget
function CognitiveProcess:forget(key, threshold)
   return self:syscall("forget", key, threshold)
end

-- Attend to something
function CognitiveProcess:attend(target, spreadFactor)
   self.attentionFocus = target
   return self:syscall("attend", target, spreadFactor)
end

-- Spawn a child agent
function CognitiveProcess:spawnAgent(config)
   return self:syscall("spawn_agent", config)
end

-- Query knowledge
function CognitiveProcess:queryKnowledge(pattern)
   return self:syscall("query_knowledge", pattern)
end

-- Send thought to another process
function CognitiveProcess:sendThought(targetPid, thought)
   self.stats.messagesSent = self.stats.messagesSent + 1
   return self:syscall("send_thought", targetPid, thought)
end

-- Receive thought
function CognitiveProcess:receiveThought(blocking)
   return self:syscall("receive_thought", blocking)
end

-- Shift consciousness level
function CognitiveProcess:shiftConsciousness(level)
   self.consciousnessLevel = level
   return self:syscall("shift_consciousness", level)
end

-- Get process status
function CognitiveProcess:getStatus()
   return {
      pid = self.pid,
      ppid = self.ppid,
      name = self.name,
      role = self.role,
      state = self.state,
      cognitiveType = self.cognitiveType,
      priority = self.priority,
      emotion = self.emotion,
      consciousnessLevel = self.consciousnessLevel,
      workingMemorySize = #self.workingMemory,
      messageQueueSize = #self.messageQueue,
      stats = self.stats,
      cpuTime = self.cpuTime,
      uptime = os.time() - self.created
   }
end

-- Terminate process
function CognitiveProcess:terminate()
   self.state = "terminated"
   -- Clean up working memory
   self.workingMemory = {}
   self.messageQueue = {}
end

function CognitiveProcess:__tostring__()
   return string.format(
      'nn.CognitiveProcess(pid=%d, name=%s, state=%s, emotion=%s, consciousness=L%d)',
      self.pid,
      self.name,
      self.state,
      self.emotion.type,
      self.consciousnessLevel
   )
end
