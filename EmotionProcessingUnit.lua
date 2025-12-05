------------------------------------------------------------------------
--[[ EmotionProcessingUnit ]]--
-- Discrete emotion channels with dimensional affect
-- Part of NNECCO-A9NN cognitive architecture
------------------------------------------------------------------------
local EPU = torch.class('nn.EmotionProcessingUnit')

-- Emotion types
local EMOTIONS = {
   neutral = 1, happy = 2, excited = 3, annoyed = 4,
   thoughtful = 5, confused = 6, curious = 7,
   determined = 8, playful = 9, sarcastic = 10
}

function EPU:__init()
   self.numEmotions = 10
   self.emotionVector = torch.zeros(self.numEmotions)
   self.emotionVector[EMOTIONS.neutral] = 1.0
   
   -- Dimensional affect
   self.valence = 0.0  -- -1 to 1
   self.arousal = 0.5  -- 0 to 1
   
   self.currentEmotion = "neutral"
   self.history = {}
   self.maxHistory = 100
end

function EPU:setEmotion(emotionType, intensity, valence)
   intensity = math.max(0, math.min(1, intensity or 0.5))
   valence = valence or 0
   valence = math.max(-1, math.min(1, valence))
   
   -- Update emotion vector
   self.emotionVector:zero()
   local idx = EMOTIONS[emotionType]
   if idx then
      self.emotionVector[idx] = intensity
   else
      -- Default to neutral if unknown emotion
      self.emotionVector[EMOTIONS.neutral] = intensity
      emotionType = "neutral"
   end
   
   self.currentEmotion = emotionType
   self.valence = valence
   self.arousal = intensity
   
   -- Record in history
   table.insert(self.history, {
      emotion = emotionType,
      intensity = intensity,
      valence = valence,
      timestamp = os.time()
   })
   
   -- Trim history
   while #self.history > self.maxHistory do
      table.remove(self.history, 1)
   end
end

function EPU:getEmotionTensor()
   return self.emotionVector:clone()
end

function EPU:modulateReservoir()
   -- Returns modulation parameters for ESRP
   return {
      input_scale_modifier = 1.0 + 0.3 * self.arousal,
      leak_rate_modifier = 1.0 - 0.2 * self.arousal,
      exploration_bonus = self.arousal * 0.2
   }
end

function EPU:getReservoirModulation(frame)
   local base_modulation = self:modulateReservoir()
   
   -- Frame-specific adjustments
   if frame == "chaos" then
      base_modulation.exploration_bonus = base_modulation.exploration_bonus * 1.5
   elseif frame == "strategy" then
      base_modulation.exploration_bonus = base_modulation.exploration_bonus * 0.5
   end
   
   return base_modulation
end

function EPU:getHistory()
   return self.history
end

function EPU:__tostring__()
   return string.format('nn.EmotionProcessingUnit(emotion=%s, valence=%.2f, arousal=%.2f)',
      self.currentEmotion, self.valence, self.arousal)
end
