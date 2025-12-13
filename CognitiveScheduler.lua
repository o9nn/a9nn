------------------------------------------------------------------------
--[[ CognitiveScheduler ]]--
-- Consciousness-aware process scheduler for Inferno kernel
-- Schedules cognitive processes based on:
-- - Consciousness level (higher = more CPU time)
-- - Emotional state (arousal affects priority)
-- - Attention focus (focused processes get priority)
-- - Learning phase (consolidation requires uninterrupted time)
------------------------------------------------------------------------
local CognitiveScheduler = torch.class('nn.CognitiveScheduler')

function CognitiveScheduler:__init(kernel, config)
   config = config or {}
   
   self.kernel = kernel
   
   -- Scheduling policy
   self.policy = config.policy or "consciousness_aware"  -- round_robin, priority, consciousness_aware
   
   -- Time quantum for each process (milliseconds)
   self.timeQuantum = config.timeQuantum or 100
   
   -- Ready queue (processes ready to run)
   self.readyQueue = {}
   
   -- Blocked queue (processes waiting for events)
   self.blockedQueue = {}
   
   -- Current running process
   self.currentProcess = nil
   
   -- Scheduling statistics
   self.stats = {
      totalSchedules = 0,
      contextSwitches = 0,
      consciousnessBoosts = 0,
      emotionAdjustments = 0
   }
   
   -- Consciousness level weights (higher consciousness = more CPU)
   self.consciousnessWeights = {
      [0] = 1.0,  -- L0: Sensorimotor
      [1] = 1.5,  -- L1: Frame-aware
      [2] = 2.0,  -- L2: Meta-cognitive
      [3] = 3.0   -- L3: Self-aware
   }
   
   -- Last schedule time
   self.lastScheduleTime = os.time()
end

-- Add process to ready queue
function CognitiveScheduler:enqueue(process)
   if not process or process.state == "terminated" then
      return false
   end
   
   process.state = "ready"
   table.insert(self.readyQueue, process)
   
   -- Sort by priority if using priority scheduling
   if self.policy == "priority" or self.policy == "consciousness_aware" then
      self:sortReadyQueue()
   end
   
   return true
end

-- Remove and return next process to run
function CognitiveScheduler:dequeue()
   if #self.readyQueue == 0 then
      return nil
   end
   
   if self.policy == "consciousness_aware" then
      return self:selectConsciousnessAware()
   elseif self.policy == "priority" then
      return table.remove(self.readyQueue, 1)
   else  -- round_robin
      return table.remove(self.readyQueue, 1)
   end
end

-- Select next process using consciousness-aware scheduling
function CognitiveScheduler:selectConsciousnessAware()
   if #self.readyQueue == 0 then
      return nil
   end
   
   -- Calculate scores for each process
   local scores = {}
   for i, process in ipairs(self.readyQueue) do
      local score = self:calculateProcessScore(process)
      scores[i] = {index = i, score = score, process = process}
   end
   
   -- Sort by score (highest first)
   table.sort(scores, function(a, b) return a.score > b.score end)
   
   -- Remove and return highest scoring process
   local selected = scores[1]
   table.remove(self.readyQueue, selected.index)
   
   if selected.process.consciousnessLevel >= 2 then
      self.stats.consciousnessBoosts = self.stats.consciousnessBoosts + 1
   end
   
   return selected.process
end

-- Calculate process score for scheduling
function CognitiveScheduler:calculateProcessScore(process)
   local score = 0
   
   -- Base priority (inverted: lower priority number = higher score)
   score = score + (10 - process.priority) * 10
   
   -- Consciousness level weight
   local consciousnessWeight = self.consciousnessWeights[process.consciousnessLevel] or 1.0
   score = score * consciousnessWeight
   
   -- Emotional arousal (high arousal = higher priority)
   if process.emotion and process.emotion.arousal then
      score = score * (1.0 + process.emotion.arousal * 0.5)
      self.stats.emotionAdjustments = self.stats.emotionAdjustments + 1
   end
   
   -- Attention focus bonus
   if process.attentionFocus then
      score = score * 1.3
   end
   
   -- Starvation prevention (processes waiting long get bonus)
   local waitTime = os.time() - process.lastScheduled
   if waitTime > 10 then
      score = score * (1.0 + waitTime / 100.0)
   end
   
   return score
end

-- Sort ready queue by priority
function CognitiveScheduler:sortReadyQueue()
   table.sort(self.readyQueue, function(a, b)
      if self.policy == "consciousness_aware" then
         return self:calculateProcessScore(a) > self:calculateProcessScore(b)
      else
         return a.priority < b.priority
      end
   end)
end

-- Schedule next process
function CognitiveScheduler:schedule()
   self.stats.totalSchedules = self.stats.totalSchedules + 1
   
   -- If current process is still running and has time left, continue
   if self.currentProcess and self.currentProcess.state == "running" then
      -- Check if quantum expired
      local now = os.time()
      if now - self.lastScheduleTime < (self.timeQuantum / 1000) then
         return self.currentProcess
      end
      
      -- Quantum expired, preempt
      self:preempt(self.currentProcess)
   end
   
   -- Get next process
   local nextProcess = self:dequeue()
   
   if nextProcess then
      self:contextSwitch(nextProcess)
      return nextProcess
   end
   
   -- No processes ready, run idle
   return nil
end

-- Context switch to new process
function CognitiveScheduler:contextSwitch(process)
   if self.currentProcess and self.currentProcess ~= process then
      self.stats.contextSwitches = self.stats.contextSwitches + 1
   end
   
   self.currentProcess = process
   process.state = "running"
   process.lastScheduled = os.time()
   self.lastScheduleTime = os.time()
end

-- Preempt current process
function CognitiveScheduler:preempt(process)
   if process.state == "running" then
      process.state = "ready"
      self:enqueue(process)
   end
end

-- Block process (waiting for event)
function CognitiveScheduler:block(process, reason)
   process.state = "blocked"
   process.blockReason = reason
   
   table.insert(self.blockedQueue, process)
   
   if self.currentProcess == process then
      self.currentProcess = nil
   end
end

-- Unblock process
function CognitiveScheduler:unblock(process)
   -- Find and remove from blocked queue
   for i, p in ipairs(self.blockedQueue) do
      if p == process then
         table.remove(self.blockedQueue, i)
         process.state = "ready"
         process.blockReason = nil
         self:enqueue(process)
         return true
      end
   end
   
   return false
end

-- Yield current process
function CognitiveScheduler:yield()
   if self.currentProcess then
      self:preempt(self.currentProcess)
      self.currentProcess = nil
   end
end

-- Get scheduler status
function CognitiveScheduler:getStatus()
   return {
      policy = self.policy,
      readyQueueSize = #self.readyQueue,
      blockedQueueSize = #self.blockedQueue,
      currentProcess = self.currentProcess and self.currentProcess.pid or nil,
      stats = self.stats
   }
end

-- Adjust process priority
function CognitiveScheduler:setPriority(process, newPriority)
   process.priority = newPriority
   
   -- Re-sort ready queue if process is in it
   self:sortReadyQueue()
end

-- Boost process priority temporarily
function CognitiveScheduler:boostPriority(process, duration)
   local originalPriority = process.priority
   process.priority = math.max(0, process.priority - 3)
   
   -- Would need timer to restore priority after duration
   -- Simplified for now
end

function CognitiveScheduler:__tostring__()
   local status = self:getStatus()
   return string.format(
      'nn.CognitiveScheduler(policy=%s, ready=%d, blocked=%d, switches=%d)',
      status.policy,
      status.readyQueueSize,
      status.blockedQueueSize,
      status.stats.contextSwitches
   )
end
