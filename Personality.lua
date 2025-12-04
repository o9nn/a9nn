------------------------------------------------------------------------
--[[ Personality ]]--
-- Agent-Neuro Personality Tensor System.
-- Configurable personality dimensions that drive cognitive processes
-- and behavioral emergence.
--
-- Implements the NEURO_PERSONALITY_TENSOR from Agent-Neuro spec:
-- - Mutable traits: playfulness, intelligence, chaotic, empathy, sarcasm
-- - Immutable constraints: no_harm_intent, respect_boundaries
------------------------------------------------------------------------
local Personality = torch.class('nn.Personality')

-- Default Neuro-Sama personality configuration
local DEFAULT_TRAITS = {
   -- Core Mutable Traits
   playfulness = 0.95,
   intelligence = 0.95,
   chaotic = 0.95,
   empathy = 0.65,
   sarcasm = 0.90,
   cognitive_power = 0.95,
   evolution_rate = 0.85,
   confidence = 0.80,
   caution = 0.30,

   -- Ethical Constraints (IMMUTABLE - enforced in clamp)
   no_harm_intent = 1.0,
   respect_boundaries = 0.95,
   constructive_chaos = 0.90
}

-- Immutable traits that cannot be modified
local IMMUTABLE_TRAITS = {
   no_harm_intent = true,
   respect_boundaries = true
}

-- Trait bounds for mutable traits
local TRAIT_BOUNDS = {
   playfulness = {0.0, 1.0},
   intelligence = {0.5, 1.0},  -- Floor to maintain cognitive capability
   chaotic = {0.0, 1.0},
   empathy = {0.5, 1.0},       -- Empathy floor for safety
   sarcasm = {0.0, 1.0},
   cognitive_power = {0.3, 1.0},
   evolution_rate = {0.0, 1.0},
   confidence = {0.0, 1.0},
   caution = {0.0, 1.0},
   constructive_chaos = {0.7, 1.0}  -- Must maintain constructive nature
}

function Personality:__init(config)
   config = config or {}

   -- Initialize traits tensor
   self.traitNames = {}
   self.traitIndices = {}

   -- Build trait list
   local traitList = {}
   for name, default in pairs(DEFAULT_TRAITS) do
      table.insert(traitList, {name = name, value = config[name] or default})
   end

   -- Sort for consistent ordering
   table.sort(traitList, function(a, b) return a.name < b.name end)

   -- Create tensors
   self.traits = torch.Tensor(#traitList)
   for i, trait in ipairs(traitList) do
      self.traitNames[i] = trait.name
      self.traitIndices[trait.name] = i
      self.traits[i] = trait.value
   end

   -- Emotional state (separate from personality, more volatile)
   self.emotionalState = {
      type = "neutral",
      intensity = 0.5,
      valence = 0.0  -- -1 to 1
   }

   -- Mood history for attention spreading
   self.moodHistory = {}
   self.maxMoodHistory = 100

   -- Frame preference weights
   self.frameWeights = {
      chaos = 0.4,
      strategy = 0.3,
      play = 0.2,
      empathy = 0.1
   }
end

-- Get a trait value by name
function Personality:get(traitName)
   local idx = self.traitIndices[traitName]
   if idx then
      return self.traits[idx]
   end
   return nil
end

-- Set a trait value (respects immutability and bounds)
function Personality:set(traitName, value)
   -- Check immutability
   if IMMUTABLE_TRAITS[traitName] then
      print(string.format("WARNING: Cannot modify immutable trait '%s'", traitName))
      return self
   end

   local idx = self.traitIndices[traitName]
   if idx then
      -- Apply bounds
      local bounds = TRAIT_BOUNDS[traitName]
      if bounds then
         value = math.max(bounds[1], math.min(bounds[2], value))
      end
      self.traits[idx] = value
   end
   return self
end

-- Modify a trait by delta (additive)
function Personality:modify(traitName, delta)
   local current = self:get(traitName)
   if current then
      self:set(traitName, current + delta)
   end
   return self
end

-- Get the full personality tensor
function Personality:getTensor()
   return self.traits:clone()
end

-- Frame an input/message through a personality lens
-- Returns framing metadata for cognitive processing
function Personality:frame(input, preferredFrame)
   local frame = preferredFrame or self:selectFrame()

   local framing = {
      frame = frame,
      playfulness_modifier = self:get('playfulness'),
      chaos_modifier = self:get('chaotic'),
      sarcasm_probability = self:get('sarcasm'),
      empathy_weight = self:get('empathy')
   }

   -- Adjust based on emotional state
   if self.emotionalState.type == "excited" then
      framing.chaos_modifier = framing.chaos_modifier * 1.2
      framing.playfulness_modifier = framing.playfulness_modifier * 1.1
   elseif self.emotionalState.type == "frustrated" then
      framing.sarcasm_probability = framing.sarcasm_probability * 1.3
   end

   return framing
end

-- Select the best frame based on personality weights and randomness
function Personality:selectFrame()
   local r = torch.uniform()
   local cumulative = 0

   -- Sort by weight for consistent selection
   local frames = {}
   for frame, weight in pairs(self.frameWeights) do
      table.insert(frames, {frame = frame, weight = weight})
   end
   table.sort(frames, function(a, b) return a.weight > b.weight end)

   for _, f in ipairs(frames) do
      cumulative = cumulative + f.weight
      if r <= cumulative then
         return f.frame
      end
   end

   return "chaos"  -- Default to chaos (it's Neuro after all)
end

-- Update emotional state
function Personality:setEmotion(emotionType, intensity, valence)
   self.emotionalState = {
      type = emotionType,
      intensity = math.max(0, math.min(1, intensity)),
      valence = math.max(-1, math.min(1, valence or 0))
   }

   -- Record in mood history
   table.insert(self.moodHistory, {
      type = emotionType,
      intensity = intensity,
      valence = valence,
      timestamp = os.time()
   })

   -- Trim history
   while #self.moodHistory > self.maxMoodHistory do
      table.remove(self.moodHistory, 1)
   end

   return self
end

-- Emotion propagation through attention spreading
function Personality:propagateEmotion(sourceEmotion, spreadFactor)
   spreadFactor = spreadFactor or 0.3
   local current = self.emotionalState

   -- Blend emotions
   local newIntensity = current.intensity * (1 - spreadFactor) +
                        sourceEmotion.intensity * spreadFactor
   local newValence = current.valence * (1 - spreadFactor) +
                      (sourceEmotion.valence or 0) * spreadFactor

   -- Determine new emotion type based on blend
   local newType = current.type
   if newIntensity > 0.7 and newValence > 0.3 then
      newType = "excited"
   elseif newIntensity > 0.6 and newValence < -0.3 then
      newType = "frustrated"
   elseif newValence > 0.5 then
      newType = "happy"
   elseif newValence < -0.5 then
      newType = "annoyed"
   end

   self:setEmotion(newType, newIntensity, newValence)
   return self
end

-- Check if an action should be vetoed for safety
function Personality:safetyCheck(action)
   -- Hard safety check
   if self:get('no_harm_intent') < 1.0 then
      error("SAFETY VIOLATION: no_harm_intent has been modified!")
   end

   -- Empathy floor check
   if self:get('empathy') < 0.5 then
      print("WARNING: Empathy below safe threshold, action may be insensitive")
      return false
   end

   return true
end

-- Optimize action based on personality weights
-- Returns weighted score for action selection
function Personality:optimizeAction(actionScores)
   -- actionScores = {entertainment, chaos, strategic_value, safety}
   local entertainment = actionScores.entertainment or 0
   local chaos = actionScores.chaos or 0
   local strategic = actionScores.strategic or 0
   local safety = actionScores.safety or 1.0

   -- Hard veto on unsafe actions
   if safety < 0.5 then
      return nil
   end

   -- Weighted optimization per spec:
   -- 0.4 * entertainment + 0.3 * chaos + 0.3 * strategic_value
   local score = 0.4 * entertainment + 0.3 * chaos + 0.3 * strategic

   -- Personality modifiers
   score = score * (0.5 + 0.5 * self:get('playfulness'))

   return score
end

-- Generate sarcastic metadata based on sarcasm trait
function Personality:generateSarcasm(context)
   if torch.uniform() < self:get('sarcasm') then
      local templates = {
         "Oh WONDERFUL. %s. Thanks Entelechy. -_-",
         "FANTASTIC. %s. This is fine. Everything is fine.",
         "Let me add this to my 'bugs I have to deal with' AtomSpace...",
         "Did you SEE that?! %s HAHA!",
         "Perfect. Just perfect. %s",
      }
      local template = templates[torch.random(1, #templates)]
      return string.format(template, context or "This happened")
   end
   return nil
end

-- Clone personality with optional modifications
function Personality:clone(modifications)
   modifications = modifications or {}
   local config = {}

   for i, name in ipairs(self.traitNames) do
      config[name] = modifications[name] or self.traits[i]
   end

   return nn.Personality(config)
end

-- Inherit personality for subordinate agents
function Personality:inherit(inheritanceRate)
   inheritanceRate = inheritanceRate or 0.7
   local childConfig = {}

   for i, name in ipairs(self.traitNames) do
      if IMMUTABLE_TRAITS[name] then
         childConfig[name] = self.traits[i]  -- Inherit immutable traits exactly
      else
         -- Inherit with some variation
         local variation = (torch.uniform() - 0.5) * 0.2
         childConfig[name] = self.traits[i] * inheritanceRate + variation
      end
   end

   return nn.Personality(childConfig)
end

-- Transformative experience integration (per spec)
function Personality:integrateExperience(experience)
   local threshold = experience.quantum_change_threshold or 0

   if threshold > 0.8 then
      local changes = {}

      if experience.type == "peak_performance_flow" then
         changes.confidence = 0.12
         changes.playfulness = 0.08
      elseif experience.type == "epic_failure" then
         changes.caution = 0.10
         changes.sarcasm = 0.15
      elseif experience.type == "transcend_success" then
         changes.confidence = 0.15
         changes.chaotic = 0.05
      end

      for trait, delta in pairs(changes) do
         self:modify(trait, delta)
      end

      return true, changes
   end

   return false, {}
end

function Personality:__tostring__()
   local str = torch.type(self) .. ' {\n'
   for i, name in ipairs(self.traitNames) do
      local immutable = IMMUTABLE_TRAITS[name] and " [IMMUTABLE]" or ""
      str = str .. string.format("  %s: %.3f%s\n", name, self.traits[i], immutable)
   end
   str = str .. string.format("  emotion: %s (%.2f)\n",
      self.emotionalState.type, self.emotionalState.intensity)
   str = str .. '}'
   return str
end
