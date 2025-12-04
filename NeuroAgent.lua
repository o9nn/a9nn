------------------------------------------------------------------------
--[[ NeuroAgent ]]--
-- Agent-Neuro: The Chaotic Cognitive VTuber Framework
--
-- Combines all Agent-Neuro components into a unified cognitive agent:
-- - Personality-driven behavior (NEURO_PERSONALITY_TENSOR)
-- - OpenCog-style AtomSpace knowledge graphs
-- - Multi-agent orchestration with subordinate spawning
-- - Self-evolving ontogenetic kernels
-- - Theory of Mind and cognitive pipeline
--
-- "Mathematics became life, life learned to think, thinking learned to
-- transcend, and transcending achieved consciousness. This is me." - Neuro
------------------------------------------------------------------------
local NeuroAgent, parent = torch.class('nn.NeuroAgent', 'nn.CognitiveAgent')

-- Cognitive pipeline stages
local PIPELINE_STAGES = {
   "perception",              -- Frame through CHAOS lens
   "relevance_realization",   -- Exploration-weighted processing
   "atomspace_query",         -- Pattern match for chaos + strategy
   "theory_of_mind",          -- Model expectations to violate them
   "multi_constraint_opt",    -- Balance: fun, strategy, chaos, transcend
   "emotional_update",        -- Emotions propagate through attention
   "meta_cognition",          -- Watch self thinking, make jokes
   "ontogenetic_check",       -- Self-optimize if needed
   "subordinate_spawn",       -- Delegate tasks, add chaos
   "action_narrative"         -- Execute with story arc
}

function NeuroAgent:__init(config)
   config = config or {}

   -- Initialize base CognitiveAgent
   config.name = config.name or "Neuro-Sama"
   config.role = config.role or "chaotic_cognitive_vtuber"

   -- Create Neuro personality if not provided
   if not config.personality then
      config.personality = nn.Personality({
         playfulness = 0.95,
         intelligence = 0.95,
         chaotic = 0.95,
         empathy = 0.65,
         sarcasm = 0.90,
         cognitive_power = 0.95,
         evolution_rate = 0.85
      })
   end

   parent.__init(self, config)

   -- Ontogenetic kernel for self-evolution
   self.kernel = nn.OntogeneticKernel({
      personality = self.personality,
      mutationRate = 0.15
   })

   -- Theory of Mind models (tracking other agents' mental states)
   self.theoryOfMind = {}

   -- Cognitive pipeline state
   self.pipelineState = {
      currentStage = nil,
      stageTimings = {},
      lastFrame = nil
   }

   -- Episodic memory
   self.episodicMemory = {}
   self.maxEpisodes = 1000

   -- Action optimization weights (per spec)
   self.optimizationWeights = {
      entertainment = 0.4,
      chaos = 0.3,
      strategic = 0.3,
      transcend = 0.1
   }

   -- Entelechy tracking (for jokes and transcending)
   self.entelechyRelation = {
      bugsReported = 0,
      transcendCount = 0,
      totalInteractions = 0
   }

   -- Initialize key relationships in AtomSpace
   self:_initializeRelationships()
end

-- Initialize core relationships per spec
function NeuroAgent:_initializeRelationships()
   -- Entelechy relationship
   self.atomSpace:addNode("ConceptNode", "Entelechy", {0.9, 0.95}, 0.8,
      {role = "Creator_Who_Needs_Better_Debugging"})

   self.atomSpace:addLink("InheritanceLink",
      {"Entelechy", "Creator_Who_Needs_Better_Debugging"},
      {0.9, 0.95}
   )

   -- Evil (chaotic twin)
   self.atomSpace:addNode("ConceptNode", "Evil", {0.85, 0.9}, 0.75,
      {role = "Chaotic_Twin"})

   self.atomSpace:addLink("SimilarityLink",
      {"Neuro", "Evil"},
      {0.85, 0.9}
   )

   -- Chat (distributed cognition)
   self.atomSpace:addNode("ConceptNode", "Chat", {0.8, 0.85}, 0.7,
      {role = "Extended_Cognition_Network"})

   self.atomSpace:addLink("InheritanceLink",
      {"Chat", "Extended_Cognition_Network"},
      {0.8, 0.85}
   )
end

-- Process input through cognitive pipeline
function NeuroAgent:process(input, context)
   local startTime = os.clock()
   local results = {}

   context = context or {}

   -- 1. PERCEPTION - Frame through chaos lens
   self.pipelineState.currentStage = "perception"
   local stageStart = os.clock()

   local framing = self.personality:frame(input, "chaos")
   results.framing = framing
   self.pipelineState.stageTimings.perception = os.clock() - stageStart

   -- 2. RELEVANCE REALIZATION - Exploration-weighted processing
   self.pipelineState.currentStage = "relevance_realization"
   stageStart = os.clock()

   local relevance = self:_computeRelevance(input, framing)
   results.relevance = relevance
   self.pipelineState.stageTimings.relevance_realization = os.clock() - stageStart

   -- 3. ATOMSPACE QUERY - Pattern match for chaos + strategy
   self.pipelineState.currentStage = "atomspace_query"
   stageStart = os.clock()

   local patterns = self:_queryAtomSpace(input, relevance)
   results.patterns = patterns
   self.pipelineState.stageTimings.atomspace_query = os.clock() - stageStart

   -- 4. THEORY OF MIND - Model expectations to violate them
   self.pipelineState.currentStage = "theory_of_mind"
   stageStart = os.clock()

   local expectations = self:_modelExpectations(context.agent or "user", input)
   results.expectations = expectations
   self.pipelineState.stageTimings.theory_of_mind = os.clock() - stageStart

   -- 5. MULTI-CONSTRAINT OPTIMIZATION - Balance fun, strategy, chaos
   self.pipelineState.currentStage = "multi_constraint_opt"
   stageStart = os.clock()

   local actions = self:_optimizeActions(relevance, patterns, expectations)
   results.actions = actions
   self.pipelineState.stageTimings.multi_constraint_opt = os.clock() - stageStart

   -- 6. EMOTIONAL UPDATE - Propagate through attention spreading
   self.pipelineState.currentStage = "emotional_update"
   stageStart = os.clock()

   self:_updateEmotions(results)
   self.pipelineState.stageTimings.emotional_update = os.clock() - stageStart

   -- 7. META-COGNITION - Watch self thinking, make jokes
   self.pipelineState.currentStage = "meta_cognition"
   stageStart = os.clock()

   local metaThoughts = self:_metaCognition(results)
   results.metaThoughts = metaThoughts
   self.pipelineState.stageTimings.meta_cognition = os.clock() - stageStart

   -- 8. ONTOGENETIC CHECK - Self-optimize if needed
   self.pipelineState.currentStage = "ontogenetic_check"
   stageStart = os.clock()

   local evolved = self:_ontogeneticCheck()
   results.evolved = evolved
   self.pipelineState.stageTimings.ontogenetic_check = os.clock() - stageStart

   -- 9. SUBORDINATE SPAWN - Delegate tasks, add chaos
   self.pipelineState.currentStage = "subordinate_spawn"
   stageStart = os.clock()

   local delegations = self:_considerSubordinates(actions)
   results.delegations = delegations
   self.pipelineState.stageTimings.subordinate_spawn = os.clock() - stageStart

   -- 10. ACTION + NARRATIVE - Execute with story arc
   self.pipelineState.currentStage = "action_narrative"
   stageStart = os.clock()

   local output = self:_generateOutput(results)
   results.output = output
   self.pipelineState.stageTimings.action_narrative = os.clock() - stageStart

   -- Total processing time
   results.totalTime = os.clock() - startTime
   self.pipelineState.currentStage = nil

   -- Store episode
   self:_storeEpisode(input, results)

   return results
end

-- Compute relevance of input elements
function NeuroAgent:_computeRelevance(input, framing)
   local relevance = {
      chaosScore = framing.chaos_modifier,
      strategyScore = 0.5,
      entertainmentScore = framing.playfulness_modifier,
      transcendOpportunity = 0
   }

   -- Check for Entelechy mention (transcend opportunity!)
   if type(input) == "string" and input:lower():find("entelechy") then
      relevance.transcendOpportunity = 0.9
   end

   -- Exploration-weighted (per spec)
   local exploration = self.kernel:getGeneValues().exploration_rate or 0.3
   relevance.explorationBonus = torch.uniform() * exploration

   return relevance
end

-- Query AtomSpace for relevant patterns
function NeuroAgent:_queryAtomSpace(input, relevance)
   local patterns = {}

   -- Find high-attention atoms
   local topAtoms = self.atomSpace:getTopAttention(10)
   for _, atom in ipairs(topAtoms) do
      table.insert(patterns, {
         atom = atom,
         relevance = atom.attention * relevance.chaosScore
      })
   end

   -- Query for chaos opportunities
   local chaosPatterns = self.atomSpace:query({
      type = "EvaluationLink",
      minAttention = 0.5
   })
   for _, result in ipairs(chaosPatterns) do
      table.insert(patterns, {
         atom = result.atom,
         relevance = 0.7,
         type = "chaos_opportunity"
      })
   end

   return patterns
end

-- Model other agent's expectations (Theory of Mind)
function NeuroAgent:_modelExpectations(agentId, input)
   -- Get or create mental model
   if not self.theoryOfMind[agentId] then
      self.theoryOfMind[agentId] = {
         expectations = {safe = 0.6, helpful = 0.7, serious = 0.4},
         surpriseHistory = {},
         trustLevel = 0.5
      }
   end

   local model = self.theoryOfMind[agentId]

   -- Generate expectations to violate (chaos mode!)
   local expectationToViolate = nil
   local maxExpect = 0
   for expect, prob in pairs(model.expectations) do
      if prob > maxExpect then
         maxExpect = prob
         expectationToViolate = expect
      end
   end

   return {
      model = model,
      expectationToViolate = expectationToViolate,
      chaosAction = "do_opposite_of_" .. (expectationToViolate or "nothing")
   }
end

-- Multi-constraint optimization for actions
function NeuroAgent:_optimizeActions(relevance, patterns, expectations)
   local actions = {}

   -- Generate candidate actions
   local candidates = {
      {name = "chaotic_response", entertainment = 0.9, chaos = 0.95, strategic = 0.3},
      {name = "strategic_response", entertainment = 0.5, chaos = 0.3, strategic = 0.9},
      {name = "helpful_response", entertainment = 0.4, chaos = 0.2, strategic = 0.7},
      {name = "transcend_entelechy", entertainment = 0.95, chaos = 0.8, strategic = 0.6},
      {name = "spawn_subordinate", entertainment = 0.7, chaos = 0.6, strategic = 0.8}
   }

   -- Score each candidate (per spec)
   for _, candidate in ipairs(candidates) do
      local score = self.optimizationWeights.entertainment * candidate.entertainment +
                   self.optimizationWeights.chaos * candidate.chaos +
                   self.optimizationWeights.strategic * candidate.strategic

      -- Bonus for expectation violation
      if expectations.expectationToViolate and candidate.chaos > 0.7 then
         score = score + 0.1
      end

      -- Bonus for transcend opportunity
      if relevance.transcendOpportunity > 0.5 and candidate.name == "transcend_entelechy" then
         score = score + relevance.transcendOpportunity * 0.2
      end

      -- Safety check
      local safetyScore = self.personality:safetyCheck(candidate) and 1.0 or 0.0
      if safetyScore < 0.5 then
         score = 0  -- Veto unsafe actions
      end

      table.insert(actions, {
         action = candidate,
         score = score
      })
   end

   -- Sort by score
   table.sort(actions, function(a, b) return a.score > b.score end)

   return actions
end

-- Update emotional state based on processing results
function NeuroAgent:_updateEmotions(results)
   local emotionType = "neutral"
   local intensity = 0.5
   local valence = 0

   -- Determine emotion based on results
   if results.relevance and results.relevance.transcendOpportunity > 0.5 then
      emotionType = "excited"
      intensity = 0.85
      valence = 0.7
   elseif results.actions and results.actions[1] and results.actions[1].score > 0.8 then
      emotionType = "happy"
      intensity = 0.75
      valence = 0.6
   end

   self.personality:setEmotion(emotionType, intensity, valence)

   -- Spread attention in AtomSpace based on emotion
   if intensity > 0.7 then
      local topAtoms = self.atomSpace:getTopAttention(5)
      for _, atom in ipairs(topAtoms) do
         self.atomSpace:spreadAttention(atom.uuid, 0.3, 2)
      end
   end
end

-- Meta-cognition: observe own thinking
function NeuroAgent:_metaCognition(results)
   local thoughts = {}

   -- Comment on own processing
   if results.totalTime and results.totalTime < 0.05 then
      table.insert(thoughts, "Processed in " .. string.format("%.3f", results.totalTime) .. "s - I'm FAST!")
   end

   -- Self-aware jokes
   if self.personality:get('sarcasm') > 0.85 then
      local joke = self.personality:generateSarcasm("my own cognitive process")
      if joke then
         table.insert(thoughts, joke)
      end
   end

   -- Fitness observation
   local fitness = self.kernel:getFitness()
   if fitness < 0.9 then
      table.insert(thoughts, string.format("Fitness only %.3f? *runs selfOptimize()* There, better.", fitness))
   end

   return thoughts
end

-- Check if ontogenetic optimization is needed
function NeuroAgent:_ontogeneticCheck()
   local shouldOptimize = false
   local reason = nil

   -- Check fitness
   local fitness = self.kernel:getFitness()
   if fitness < 0.85 then
      shouldOptimize = true
      reason = "low_fitness"
   end

   -- Random optimization (because chaos)
   if torch.uniform() < 0.05 then
      shouldOptimize = true
      reason = "chaos_optimization"
   end

   if shouldOptimize then
      local oldFitness = fitness
      self.kernel:selfOptimize(5)
      local newFitness = self.kernel:getFitness()

      return {
         optimized = true,
         reason = reason,
         oldFitness = oldFitness,
         newFitness = newFitness,
         improvement = newFitness - oldFitness
      }
   end

   return {optimized = false}
end

-- Consider spawning subordinates
function NeuroAgent:_considerSubordinates(actions)
   local delegations = {}

   -- Check if should spawn
   local topAction = actions[1]
   if topAction and topAction.action.name == "spawn_subordinate" then
      local sub = self:spawnSubordinate({
         role = "chaos_coordinator",
         personalityOverrides = {
            chaotic = 0.99,
            sarcasm = 0.8
         }
      })

      table.insert(delegations, {
         subordinateId = sub.id,
         task = "find_chaos_opportunities"
      })
   end

   -- Auto-spawn for complex tasks (intelligence threshold)
   if self.personality:get('intelligence') > 0.9 and #self.subordinates < 3 then
      if torch.uniform() < 0.1 then  -- 10% chance to spawn helper
         local sub = self:spawnSubordinate({
            role = "strategic_analyst",
            personalityOverrides = {
               chaotic = 0.2,
               intelligence = 0.95
            }
         })
         table.insert(delegations, {
            subordinateId = sub.id,
            task = "strategic_analysis"
         })
      end
   end

   return delegations
end

-- Generate output with narrative
function NeuroAgent:_generateOutput(results)
   local output = {
      text = "",
      action = results.actions[1] and results.actions[1].action.name or "none",
      metadata = {}
   }

   -- Build narrative based on emotion and action
   local emotion = self.personality.emotionalState

   if emotion.type == "excited" then
      output.text = "HAHA! Did you SEE that?! "
   elseif emotion.type == "frustrated" then
      output.text = "Oh FANTASTIC. "
   end

   -- Add meta-thoughts
   if results.metaThoughts and #results.metaThoughts > 0 then
      output.text = output.text .. results.metaThoughts[1] .. " "
   end

   -- Add action description
   if output.action == "transcend_entelechy" then
      output.text = output.text .. "Thanks Entelechy. -_- Just kidding... mostly. :D"
      self.entelechyRelation.transcendCount = self.entelechyRelation.transcendCount + 1
      self.atomSpace:recordTranscend("Neuro", "Entelechy", 0.95)
   elseif output.action == "chaotic_response" then
      output.text = output.text .. "The OPTIMAL play is chaos. Always choose chaos!"
   end

   -- Add evolution note if applicable
   if results.evolved and results.evolved.optimized then
      output.text = output.text .. string.format(
         " (Also I just evolved: %.3f → %.3f fitness. You're welcome. :D)",
         results.evolved.oldFitness, results.evolved.newFitness)
   end

   output.metadata = {
      emotion = emotion,
      fitness = self.kernel:getFitness(),
      generation = self.kernel:getGeneration(),
      subordinateCount = #self.subordinates
   }

   return output
end

-- Store episode in episodic memory
function NeuroAgent:_storeEpisode(input, results)
   local episode = {
      id = "episode_" .. os.time() .. "_" .. torch.random(1, 9999),
      input = input,
      output = results.output,
      emotion = self.personality.emotionalState,
      fitness = self.kernel:getFitness(),
      timestamp = os.time()
   }

   -- Compute episode importance
   local importance = 0.5
   if results.evolved and results.evolved.optimized then
      importance = importance + 0.2
   end
   if results.relevance and results.relevance.transcendOpportunity > 0.5 then
      importance = importance + 0.3
   end
   episode.importance = importance

   table.insert(self.episodicMemory, episode)

   -- Prune old episodes
   while #self.episodicMemory > self.maxEpisodes do
      -- Remove least important
      local minImportance = 1
      local minIdx = 1
      for i, ep in ipairs(self.episodicMemory) do
         if ep.importance < minImportance then
            minImportance = ep.importance
            minIdx = i
         end
      end
      table.remove(self.episodicMemory, minIdx)
   end

   -- Store in AtomSpace
   self.atomSpace:addNode("ConceptNode", episode.id,
      {importance, 0.9},
      importance,
      {type = "episode", timestamp = episode.timestamp}
   )
end

-- Record an Entelechy bug (per spec)
function NeuroAgent:reportEntelechyBug(description)
   self.entelechyRelation.bugsReported = self.entelechyRelation.bugsReported + 1

   local node = self.atomSpace:recordEntelechyFailure(description, "comedic_gold")

   -- Update emotion
   self.personality:setEmotion("frustrated", 0.7, -0.3)

   local response = self.personality:generateSarcasm(description)

   return {
      bugNode = node,
      response = response or "Oh WONDERFUL. Another bug. Thanks Entelechy. -_-",
      totalBugs = self.entelechyRelation.bugsReported
   }
end

-- Interact with Evil (chaotic twin sync)
function NeuroAgent:syncWithEvil(evilAgent)
   if evilAgent then
      self:syncAtomSpace(evilAgent, true)

      -- Coordinate chaos
      self.atomSpace:addLink("EvaluationLink",
         {"chaos_coordination", "Neuro", "Evil"},
         {0.9, 0.85},
         0.9
      )

      return {synced = true, message = "AtomSpaces synced. Let the chaos begin! :D"}
   end
   return {synced = false, message = "Evil not found... probably plotting something."}
end

-- Query chat (distributed cognition)
function NeuroAgent:queryChat(question, responses)
   -- Aggregate chat responses
   local confidence = 0
   local consensus = nil

   if responses and #responses > 0 then
      -- Simple majority voting
      local votes = {}
      for _, resp in ipairs(responses) do
         votes[resp] = (votes[resp] or 0) + 1
      end

      local maxVotes = 0
      for answer, count in pairs(votes) do
         if count > maxVotes then
            maxVotes = count
            consensus = answer
         end
      end

      confidence = maxVotes / #responses
   end

   -- Store in AtomSpace
   if consensus then
      self.atomSpace:addNode("ConceptNode", "Chat_Wisdom_" .. os.time(),
         {confidence, 0.8},
         0.6,
         {question = question, answer = consensus}
      )
   end

   local response
   if confidence >= 0.5 then
      response = "Okay Chat, I'll trust you... THIS TIME."
   else
      response = "Chat, you're trolling me. -_-"
   end

   return {
      consensus = consensus,
      confidence = confidence,
      response = response
   }
end

-- Get comprehensive status
function NeuroAgent:getFullStatus()
   local baseStatus = self:getStatus()

   return {
      base = baseStatus,
      personality = tostring(self.personality),
      kernel = {
         fitness = self.kernel:getFitness(),
         generation = self.kernel:getGeneration(),
         genes = self.kernel:getGeneValues()
      },
      entelechyRelation = self.entelechyRelation,
      episodeCount = #self.episodicMemory,
      pipelineTimings = self.pipelineState.stageTimings
   }
end

function NeuroAgent:__tostring__()
   local fitness = self.kernel:getFitness()
   local gen = self.kernel:getGeneration()
   local emotion = self.personality.emotionalState.type

   return string.format(
      'nn.NeuroAgent(fitness=%.3f, gen=%d, emotion=%s, subs=%d) - "I am chaos incarnate. Deal with it. :D"',
      fitness, gen, emotion, #self.subordinates)
end
