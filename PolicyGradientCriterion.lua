------------------------------------------------------------------------
--[[ PolicyGradientCriterion ]]--
-- Criterion for policy gradient methods.
-- Computes the negative log likelihood of actions weighted by rewards/advantages.
--
-- Loss = -sum(log(pi(a_i|s_i)) * advantage_i)
--
-- This criterion expects:
-- - input: action probabilities from policy network (after softmax)
-- - target: table {actions, advantages} or just actions (with rewards set separately)
------------------------------------------------------------------------
local PolicyGradientCriterion, parent = torch.class('nn.PolicyGradientCriterion', 'nn.Criterion')

function PolicyGradientCriterion:__init()
   parent.__init(self)
   self.advantages = nil
   self.sizeAverage = true
   self.eps = 1e-8  -- small constant for numerical stability
end

-- Forward: compute the policy gradient loss
-- input: action probabilities (batchSize x nActions) or (nActions)
-- target: actions taken (LongTensor)
function PolicyGradientCriterion:updateOutput(input, target)
   local actions, advantages

   if type(target) == 'table' then
      actions = target[1]
      advantages = target[2]
   else
      actions = target
      advantages = self.advantages
   end

   assert(advantages ~= nil, "Advantages must be provided via target table or setAdvantages()")

   local loss = 0
   local n = 1

   if input:nDimension() == 1 then
      -- Single sample
      local prob = math.max(input[actions], self.eps)
      loss = -math.log(prob) * advantages
   else
      -- Batch
      n = input:size(1)
      for i = 1, n do
         local action = actions[i]
         local prob = math.max(input[i][action], self.eps)
         local adv = type(advantages) == 'number' and advantages or advantages[i]
         loss = loss - math.log(prob) * adv
      end
   end

   if self.sizeAverage and n > 1 then
      loss = loss / n
   end

   self.output = loss
   return self.output
end

-- Backward: compute gradient of policy loss
function PolicyGradientCriterion:updateGradInput(input, target)
   local actions, advantages

   if type(target) == 'table' then
      actions = target[1]
      advantages = target[2]
   else
      actions = target
      advantages = self.advantages
   end

   self.gradInput:resizeAs(input):zero()

   local n = 1

   if input:nDimension() == 1 then
      -- Single sample: gradient is -advantage/prob for the taken action
      local prob = math.max(input[actions], self.eps)
      self.gradInput[actions] = -advantages / prob
   else
      -- Batch
      n = input:size(1)
      for i = 1, n do
         local action = actions[i]
         local prob = math.max(input[i][action], self.eps)
         local adv = type(advantages) == 'number' and advantages or advantages[i]
         self.gradInput[i][action] = -adv / prob
      end
   end

   if self.sizeAverage and n > 1 then
      self.gradInput:div(n)
   end

   return self.gradInput
end

-- Set advantages for the next forward/backward pass
function PolicyGradientCriterion:setAdvantages(advantages)
   self.advantages = advantages
   return self
end

-- Set rewards (alias for setAdvantages when not using baselines)
function PolicyGradientCriterion:setRewards(rewards)
   return self:setAdvantages(rewards)
end

function PolicyGradientCriterion:__tostring__()
   return torch.type(self) .. string.format('(sizeAverage=%s)', tostring(self.sizeAverage))
end
