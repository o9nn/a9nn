------------------------------------------------------------------------
--[[ ValueFunction ]]--
-- Container module that wraps a value function approximator.
-- Provides utility methods for computing state values and TD errors.
--
-- Typically used to estimate V(s) or Q(s,a) in actor-critic methods.
------------------------------------------------------------------------
local ValueFunction, parent = torch.class('nn.ValueFunction', 'nn.Container')

function ValueFunction:__init(network)
   parent.__init(self)
   self.network = network
   if network then
      self.modules = {network}
      self.output = network.output
      self.gradInput = network.gradInput
   end
end

-- Set the value network
function ValueFunction:setNetwork(network)
   self.network = network
   self.modules = {network}
   self.output = network.output
   self.gradInput = network.gradInput
   return self
end

-- Forward pass: compute value estimate
function ValueFunction:updateOutput(input)
   self.output = self.network:updateOutput(input)
   return self.output
end

-- Backward pass
function ValueFunction:updateGradInput(input, gradOutput)
   self.gradInput = self.network:updateGradInput(input, gradOutput)
   return self.gradInput
end

function ValueFunction:accGradParameters(input, gradOutput, scale)
   self.network:accGradParameters(input, gradOutput, scale)
end

-- Compute TD error: delta = reward + gamma * V(s') - V(s)
-- values: V(s) estimates
-- nextValues: V(s') estimates
-- rewards: immediate rewards
-- dones: terminal flags (1 if terminal, 0 otherwise)
-- gamma: discount factor
function ValueFunction:computeTDError(values, nextValues, rewards, dones, gamma)
   gamma = gamma or 0.99

   local tdError = rewards:clone()

   if values:nDimension() == 1 then
      -- Single dimension values
      for i = 1, values:size(1) do
         local nextVal = dones[i] == 1 and 0 or nextValues[i]
         tdError[i] = rewards[i] + gamma * nextVal - values[i]
      end
   else
      -- Batch with extra dimension (squeeze if needed)
      local v = values:nDimension() > 1 and values:squeeze() or values
      local nv = nextValues:nDimension() > 1 and nextValues:squeeze() or nextValues

      for i = 1, v:size(1) do
         local nextVal = dones[i] == 1 and 0 or nv[i]
         tdError[i] = rewards[i] + gamma * nextVal - v[i]
      end
   end

   return tdError
end

-- Compute n-step returns
-- rewards: tensor of rewards [T] or [batch, T]
-- lastValue: V(s_T) estimate for bootstrap
-- dones: terminal flags
-- gamma: discount factor
function ValueFunction:computeReturns(rewards, lastValue, dones, gamma)
   gamma = gamma or 0.99

   local returns = rewards:clone()
   local T = rewards:size(1)

   -- Last step
   returns[T] = rewards[T] + gamma * lastValue * (1 - (dones and dones[T] or 0))

   -- Backward pass to compute returns
   for t = T - 1, 1, -1 do
      local mask = dones and (1 - dones[t]) or 1
      returns[t] = rewards[t] + gamma * returns[t + 1] * mask
   end

   return returns
end

-- Compute Generalized Advantage Estimation (GAE)
-- rewards: tensor of rewards [T]
-- values: V(s) estimates [T]
-- nextValues: V(s') estimates [T] (can be values shifted by 1 with bootstrap)
-- dones: terminal flags [T]
-- gamma: discount factor
-- lambda: GAE lambda parameter
function ValueFunction:computeGAE(rewards, values, nextValues, dones, gamma, lambda)
   gamma = gamma or 0.99
   lambda = lambda or 0.95

   local T = rewards:size(1)
   local advantages = torch.Tensor(T):zero()
   local lastGaeLam = 0

   for t = T, 1, -1 do
      local mask = dones and (1 - dones[t]) or 1
      local nextVal = nextValues[t]
      local delta = rewards[t] + gamma * nextVal * mask - values[t]
      lastGaeLam = delta + gamma * lambda * mask * lastGaeLam
      advantages[t] = lastGaeLam
   end

   return advantages
end

function ValueFunction:__tostring__()
   local tab = '  '
   local line = '\n'
   local str = torch.type(self) .. ' {' .. line
   if self.network then
      str = str .. tab .. 'network: ' .. tostring(self.network):gsub(line, line .. tab) .. line
   end
   str = str .. '}'
   return str
end
