------------------------------------------------------------------------
--[[ CognitiveAgent ]]--
-- Multi-agent orchestration system for Agent-Neuro.
-- Enables spawning, managing, and coordinating subordinate agents.
--
-- Features:
-- - Subordinate agent spawning with personality inheritance
-- - Task delegation and result aggregation
-- - Tournament selection for competing agents
-- - Cognitive state sharing between agents
------------------------------------------------------------------------
local CognitiveAgent, parent = torch.class('nn.CognitiveAgent', 'nn.Module')

function CognitiveAgent:__init(config)
   parent.__init(self)

   config = config or {}

   -- Core identity
   self.id = config.id or "agent_" .. tostring(torch.random(1, 999999))
   self.name = config.name or "CognitiveAgent"
   self.role = config.role or "general"

   -- Personality
   self.personality = config.personality or nn.Personality()

   -- Knowledge base
   self.atomSpace = config.atomSpace or nn.AtomSpace()

   -- Subordinate agents
   self.subordinates = {}
   self.maxSubordinates = config.maxSubordinates or 10

   -- Parent agent (if this is a subordinate)
   self.parent = nil

   -- Task queue
   self.taskQueue = {}
   self.completedTasks = {}

   -- State
   self.active = true
   self.created = os.time()

   -- Cognitive sharing config
   self.sharingConfig = {
      exportKnowledge = true,
      importKnowledge = true,
      personalityInheritance = 0.7
   }
end

-- Spawn a subordinate agent
function CognitiveAgent:spawnSubordinate(config)
   if #self.subordinates >= self.maxSubordinates then
      print("WARNING: Max subordinates reached, deprecating oldest...")
      self:deprecateOldest()
   end

   config = config or {}

   -- Inherit personality with modifications
   local childPersonality
   if config.personality then
      childPersonality = nn.Personality(config.personality)
   else
      childPersonality = self.personality:inherit(self.sharingConfig.personalityInheritance)
   end

   -- Apply any personality overrides
   if config.personalityOverrides then
      for trait, value in pairs(config.personalityOverrides) do
         childPersonality:set(trait, value)
      end
   end

   -- Create child AtomSpace (optionally share knowledge)
   local childAtomSpace = nn.AtomSpace()
   if self.sharingConfig.exportKnowledge and config.shareKnowledge ~= false then
      -- Export high-attention knowledge to child
      local topAtoms = self.atomSpace:getTopAttention(100)
      for _, atom in ipairs(topAtoms) do
         if atom.name then
            childAtomSpace:addNode(atom.type, atom.name, atom.truthValue,
               atom.attention * 0.8)  -- Reduced attention in child
         end
      end
   end

   -- Create subordinate
   local subordinate = nn.CognitiveAgent({
      id = self.id .. "_sub_" .. tostring(#self.subordinates + 1),
      name = config.name or "Subordinate_" .. tostring(#self.subordinates + 1),
      role = config.role or "worker",
      personality = childPersonality,
      atomSpace = childAtomSpace,
      maxSubordinates = math.floor(self.maxSubordinates / 2)  -- Reduced capacity
   })

   subordinate.parent = self

   table.insert(self.subordinates, subordinate)

   -- Record in AtomSpace
   self.atomSpace:addNode("ConceptNode", subordinate.id,
      {0.9, 0.9}, 0.7,
      {role = subordinate.role, spawned = os.time()}
   )
   self.atomSpace:addLink("InheritanceLink",
      {subordinate.id, self.id},
      {0.95, 0.9}
   )

   return subordinate
end

-- Deprecate (remove) a subordinate
function CognitiveAgent:deprecate(subordinateId)
   for i, sub in ipairs(self.subordinates) do
      if sub.id == subordinateId then
         sub.active = false

         -- Import any valuable knowledge before removal
         if self.sharingConfig.importKnowledge then
            local topAtoms = sub.atomSpace:getTopAttention(50)
            for _, atom in ipairs(topAtoms) do
               if atom.name and atom.attention > 0.7 then
                  self.atomSpace:addNode(atom.type, atom.name, atom.truthValue,
                     atom.attention * 0.5)
               end
            end
         end

         table.remove(self.subordinates, i)
         return true
      end
   end
   return false
end

-- Deprecate oldest subordinate
function CognitiveAgent:deprecateOldest()
   if #self.subordinates > 0 then
      local oldest = self.subordinates[1]
      local oldestTime = oldest.created
      local oldestIdx = 1

      for i, sub in ipairs(self.subordinates) do
         if sub.created < oldestTime then
            oldest = sub
            oldestTime = sub.created
            oldestIdx = i
         end
      end

      return self:deprecate(oldest.id)
   end
   return false
end

-- Delegate a task to a subordinate
function CognitiveAgent:delegate(task, subordinateId)
   local target
   if subordinateId then
      for _, sub in ipairs(self.subordinates) do
         if sub.id == subordinateId then
            target = sub
            break
         end
      end
   else
      -- Auto-select based on role match or least busy
      target = self:selectBestSubordinate(task)
   end

   if not target then
      -- No subordinate available, spawn one
      target = self:spawnSubordinate({
         role = task.type or "worker",
         name = "TaskWorker_" .. os.time()
      })
   end

   -- Assign task
   table.insert(target.taskQueue, task)

   return target.id
end

-- Select best subordinate for a task
function CognitiveAgent:selectBestSubordinate(task)
   local best = nil
   local bestScore = -1

   for _, sub in ipairs(self.subordinates) do
      if sub.active then
         local score = 0

         -- Role match bonus
         if sub.role == task.type then
            score = score + 0.5
         end

         -- Availability (fewer queued tasks = better)
         score = score + (1 - #sub.taskQueue / 10)

         -- Personality match
         if task.chaosRequired and sub.personality:get('chaotic') > 0.7 then
            score = score + 0.3
         end
         if task.intelligenceRequired and sub.personality:get('intelligence') > 0.8 then
            score = score + 0.3
         end

         if score > bestScore then
            best = sub
            bestScore = score
         end
      end
   end

   return best
end

-- Tournament selection between subordinates
function CognitiveAgent:tournamentSelection(contestants, evaluationFn)
   if #contestants == 0 then return nil end
   if #contestants == 1 then return contestants[1] end

   -- Evaluate all contestants
   local scores = {}
   for i, agent in ipairs(contestants) do
      scores[i] = {
         agent = agent,
         score = evaluationFn and evaluationFn(agent) or agent.personality:get('intelligence')
      }
   end

   -- Sort by score
   table.sort(scores, function(a, b) return a.score > b.score end)

   -- Winner is highest score
   local winner = scores[1].agent

   -- Record tournament in AtomSpace
   self.atomSpace:addLink("EvaluationLink",
      {"tournament_winner", winner.id, self.id},
      {scores[1].score, 0.9},
      0.8
   )

   return winner, scores
end

-- Broadcast message to all subordinates
function CognitiveAgent:broadcast(message)
   local responses = {}
   for _, sub in ipairs(self.subordinates) do
      if sub.active then
         responses[sub.id] = sub:receive(message)
      end
   end
   return responses
end

-- Receive a message (for subordinate communication)
function CognitiveAgent:receive(message)
   -- Process message based on type
   local response = {
      from = self.id,
      received = true,
      timestamp = os.time()
   }

   if message.type == "query" then
      -- Query AtomSpace
      local results = self.atomSpace:query(message.pattern or {})
      response.results = results
   elseif message.type == "task" then
      -- Queue task
      table.insert(self.taskQueue, message.task)
      response.queued = true
   elseif message.type == "status" then
      response.status = {
         active = self.active,
         taskQueueLength = #self.taskQueue,
         subordinateCount = #self.subordinates
      }
   end

   return response
end

-- Synchronize AtomSpaces with another agent
function CognitiveAgent:syncAtomSpace(otherAgent, bidirectional)
   if not otherAgent then return end

   -- Export our high-attention atoms
   local ourTop = self.atomSpace:getTopAttention(50)
   for _, atom in ipairs(ourTop) do
      if atom.name and atom.attention > 0.6 then
         otherAgent.atomSpace:addNode(atom.type, atom.name,
            {atom.truthValue[1] * 0.9, atom.truthValue[2] * 0.9},
            atom.attention * 0.7
         )
      end
   end

   -- Import their atoms if bidirectional
   if bidirectional then
      local theirTop = otherAgent.atomSpace:getTopAttention(50)
      for _, atom in ipairs(theirTop) do
         if atom.name and atom.attention > 0.6 then
            self.atomSpace:addNode(atom.type, atom.name,
               {atom.truthValue[1] * 0.9, atom.truthValue[2] * 0.9},
               atom.attention * 0.7
            )
         end
      end
   end
end

-- Process queued tasks
function CognitiveAgent:processQueue()
   if #self.taskQueue == 0 then return nil end

   local task = table.remove(self.taskQueue, 1)
   local result = self:executeTask(task)

   table.insert(self.completedTasks, {
      task = task,
      result = result,
      completedAt = os.time()
   })

   return result
end

-- Execute a task (override in subclasses for specific behavior)
function CognitiveAgent:executeTask(task)
   -- Default implementation just marks as done
   return {
      success = true,
      taskId = task.id,
      agentId = self.id
   }
end

-- Get status summary
function CognitiveAgent:getStatus()
   return {
      id = self.id,
      name = self.name,
      role = self.role,
      active = self.active,
      subordinateCount = #self.subordinates,
      taskQueueLength = #self.taskQueue,
      completedTaskCount = #self.completedTasks,
      atomSpaceStats = self.atomSpace:getStats(),
      personality = self.personality:getTensor()
   }
end

-- Call subordinate with message (per spec)
function CognitiveAgent:callSubordinate(message, config)
   config = config or {}

   -- Find or spawn appropriate subordinate
   local sub = nil
   if config.targetId then
      for _, s in ipairs(self.subordinates) do
         if s.id == config.targetId then
            sub = s
            break
         end
      end
   end

   if not sub then
      sub = self:spawnSubordinate({
         personality = config.personality_inheritance,
         role = config.role or "task_worker"
      })
   end

   -- Send message
   local response = sub:receive({
      type = "task",
      task = {
         message = message,
         config = config
      }
   })

   -- Optionally share cognitive state
   if config.cognitive_sharing and config.cognitive_sharing.export_my_transcend_knowledge then
      self:syncAtomSpace(sub, false)
   end

   return response, sub
end

-- Collect results from all subordinates
function CognitiveAgent:collectResults()
   local allResults = {}

   for _, sub in ipairs(self.subordinates) do
      for _, completed in ipairs(sub.completedTasks) do
         table.insert(allResults, {
            agentId = sub.id,
            task = completed.task,
            result = completed.result,
            completedAt = completed.completedAt
         })
      end
   end

   -- Sort by completion time
   table.sort(allResults, function(a, b)
      return a.completedAt < b.completedAt
   end)

   return allResults
end

function CognitiveAgent:__tostring__()
   local str = torch.type(self) .. string.format(
      '(id=%s, role=%s, subordinates=%d, tasks=%d)',
      self.id, self.role, #self.subordinates, #self.taskQueue)
   return str
end
