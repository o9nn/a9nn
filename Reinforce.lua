------------------------------------------------------------------------
--[[ Reinforce ]]--
-- REINFORCE (Williams, 1992) policy gradient module.
-- This module wraps a stochastic policy network and provides
-- gradient estimation using the REINFORCE algorithm.
--
-- The module samples actions from the policy's output distribution
-- and computes gradients scaled by the reward signal.
------------------------------------------------------------------------
local Reinforce, parent = torch.class('nn.Reinforce', 'nn.Module')

function Reinforce:__init(stochastic)
   parent.__init(self)
   -- If true, sample actions; if false, use argmax (greedy)
   self.stochastic = stochastic == nil and true or stochastic
   self.reward = 0
   self.baseline = 0          -- baseline for variance reduction
   self.baselineAlpha = 0.1   -- exponential moving average coefficient
   self.action = torch.Tensor()
   self._sampledAction = torch.LongTensor()
end

-- Forward pass: compute action probabilities and sample action
-- Input: action probabilities from policy network (softmax output)
-- Output: same as input (probabilities), stores sampled action internally
function Reinforce:updateOutput(input)
   self.output:resizeAs(input):copy(input)

   if self.stochastic and self.train then
      -- Sample from categorical distribution
      self:_sampleAction(input)
   else
      -- Greedy action selection (argmax)
      if input:nDimension() == 1 then
         local _, maxIdx = input:max(1)
         self._sampledAction:resize(1)
         self._sampledAction[1] = maxIdx[1]
      else
         local _, maxIdx = input:max(2)
         self._sampledAction:resize(input:size(1)):copy(maxIdx)
      end
   end

   self.action:resize(self._sampledAction:size()):copy(self._sampledAction)
   return self.output
end

-- Sample action from categorical distribution
function Reinforce:_sampleAction(probs)
   if probs:nDimension() == 1 then
      -- Single sample
      self._sampledAction:resize(1)
      local r = torch.uniform()
      local cumsum = 0
      for i = 1, probs:size(1) do
         cumsum = cumsum + probs[i]
         if r <= cumsum then
            self._sampledAction[1] = i
            break
         end
      end
      if self._sampledAction[1] == 0 then
         self._sampledAction[1] = probs:size(1)
      end
   else
      -- Batch of samples
      local batchSize = probs:size(1)
      local nActions = probs:size(2)
      self._sampledAction:resize(batchSize)

      for b = 1, batchSize do
         local r = torch.uniform()
         local cumsum = 0
         for i = 1, nActions do
            cumsum = cumsum + probs[b][i]
            if r <= cumsum then
               self._sampledAction[b] = i
               break
            end
         end
         if self._sampledAction[b] == 0 then
            self._sampledAction[b] = nActions
         end
      end
   end
end

-- Backward pass: compute policy gradient
-- The gradient is scaled by (reward - baseline) to reduce variance
function Reinforce:updateGradInput(input, gradOutput)
   local advantage = self.reward - self.baseline

   self.gradInput:resizeAs(input):zero()

   if input:nDimension() == 1 then
      -- d log(pi(a|s)) / d theta = (1/pi(a|s)) * d pi(a|s) / d theta
      -- For softmax: this simplifies to (indicator - pi) * advantage
      local action = self._sampledAction[1]
      for i = 1, input:size(1) do
         if i == action then
            self.gradInput[i] = (1 - input[i]) * advantage
         else
            self.gradInput[i] = -input[i] * advantage
         end
      end
   else
      -- Batch version
      local batchSize = input:size(1)
      for b = 1, batchSize do
         local action = self._sampledAction[b]
         local adv = type(advantage) == 'number' and advantage or advantage[b]
         for i = 1, input:size(2) do
            if i == action then
               self.gradInput[b][i] = (1 - input[b][i]) * adv
            else
               self.gradInput[b][i] = -input[b][i] * adv
            end
         end
      end
   end

   -- Add incoming gradient
   if gradOutput then
      self.gradInput:add(gradOutput)
   end

   return self.gradInput
end

-- Set the reward signal for gradient computation
function Reinforce:setReward(reward)
   self.reward = reward
   -- Update baseline using exponential moving average
   self.baseline = self.baseline * (1 - self.baselineAlpha) + reward * self.baselineAlpha
   return self
end

-- Get the sampled action
function Reinforce:getAction()
   if self._sampledAction:nDimension() == 1 and self._sampledAction:size(1) == 1 then
      return self._sampledAction[1]
   end
   return self._sampledAction
end

-- Reset baseline
function Reinforce:resetBaseline()
   self.baseline = 0
   return self
end

-- Set baseline coefficient
function Reinforce:setBaselineAlpha(alpha)
   self.baselineAlpha = alpha
   return self
end

function Reinforce:__tostring__()
   return torch.type(self) .. string.format('(stochastic=%s, baseline=%.4f)',
      tostring(self.stochastic), self.baseline)
end
