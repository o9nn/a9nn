------------------------------------------------------------------------
--[[ AdvantageActorCritic (A2C) ]]--
-- Advantage Actor-Critic implementation.
-- Combines policy gradient with a learned baseline (value function).
--
-- The advantage function A(s,a) = Q(s,a) - V(s) reduces variance
-- compared to raw returns while maintaining unbiased gradient estimates.
--
-- Supports:
-- - n-step returns
-- - Generalized Advantage Estimation (GAE)
-- - Entropy regularization
------------------------------------------------------------------------
local AdvantageActorCritic, parent = torch.class('nn.AdvantageActorCritic', 'nn.Container')

function AdvantageActorCritic:__init(actor, critic, config)
   parent.__init(self)

   config = config or {}

   self.actor = actor
   self.critic = critic

   self.gamma = config.gamma or 0.99
   self.lambda = config.lambda or 0.95  -- GAE lambda
   self.entropyCoef = config.entropyCoef or 0.01  -- entropy regularization
   self.valueLossCoef = config.valueLossCoef or 0.5  -- value loss weight
   self.maxGradNorm = config.maxGradNorm or 0.5  -- gradient clipping

   self.modules = {}
   if actor then table.insert(self.modules, actor) end
   if critic then table.insert(self.modules, critic) end

   -- Outputs
   self.output = {}
   self.gradInput = torch.Tensor()

   -- Buffers for rollout data
   self._observations = {}
   self._actions = {}
   self._rewards = {}
   self._values = {}
   self._dones = {}
   self._logProbs = {}
end

-- Forward pass
function AdvantageActorCritic:updateOutput(input)
   local policy = self.actor:updateOutput(input)
   local value = self.critic:updateOutput(input)
   self.output = {policy, value}
   return self.output
end

-- Backward pass
function AdvantageActorCritic:updateGradInput(input, gradOutput)
   local actorGrad = gradOutput[1]
   local criticGrad = gradOutput[2]

   local actorGradInput = self.actor:updateGradInput(input, actorGrad)
   local criticGradInput = self.critic:updateGradInput(input, criticGrad)

   self.gradInput:resizeAs(actorGradInput):copy(actorGradInput):add(criticGradInput)
   return self.gradInput
end

function AdvantageActorCritic:accGradParameters(input, gradOutput, scale)
   scale = scale or 1
   self.actor:accGradParameters(input, gradOutput[1], scale)
   self.critic:accGradParameters(input, gradOutput[2], scale)
end

-- Store a transition during rollout
function AdvantageActorCritic:store(observation, action, reward, value, done, logProb)
   table.insert(self._observations, observation:clone())
   table.insert(self._actions, action)
   table.insert(self._rewards, reward)
   table.insert(self._values, value)
   table.insert(self._dones, done and 1 or 0)
   if logProb then
      table.insert(self._logProbs, logProb)
   end
end

-- Clear rollout buffer
function AdvantageActorCritic:clearRollout()
   self._observations = {}
   self._actions = {}
   self._rewards = {}
   self._values = {}
   self._dones = {}
   self._logProbs = {}
end

-- Compute advantages using GAE
function AdvantageActorCritic:computeAdvantages(lastValue)
   local T = #self._rewards
   if T == 0 then
      return torch.Tensor(), torch.Tensor()
   end

   local advantages = torch.Tensor(T):zero()
   local returns = torch.Tensor(T):zero()

   local lastGaeLam = 0
   local nextValue = lastValue or 0

   for t = T, 1, -1 do
      local mask = 1 - self._dones[t]
      local delta = self._rewards[t] + self.gamma * nextValue * mask - self._values[t]
      lastGaeLam = delta + self.gamma * self.lambda * mask * lastGaeLam
      advantages[t] = lastGaeLam
      returns[t] = advantages[t] + self._values[t]
      nextValue = self._values[t]
   end

   return advantages, returns
end

-- Compute policy loss (negative of policy gradient objective)
-- policy: action probabilities [batch x nActions]
-- actions: actions taken [batch]
-- advantages: advantage estimates [batch]
function AdvantageActorCritic:computePolicyLoss(policy, actions, advantages)
   local batchSize = policy:size(1)
   local loss = 0
   local gradPolicy = torch.Tensor(policy:size()):zero()

   for i = 1, batchSize do
      local action = actions[i]
      local prob = math.max(policy[i][action], 1e-8)
      local logProb = math.log(prob)
      local advantage = advantages[i]

      -- Policy gradient loss: -log(pi(a|s)) * A(s,a)
      loss = loss - logProb * advantage

      -- Gradient: -A / pi(a)
      gradPolicy[i][action] = -advantage / prob
   end

   return loss / batchSize, gradPolicy:div(batchSize)
end

-- Compute value loss (MSE between predicted and target values)
function AdvantageActorCritic:computeValueLoss(values, returns)
   local diff = values:clone():add(-1, returns)
   local loss = diff:pow(2):mean()
   local gradValues = diff:mul(2 / values:nElement())
   return loss, gradValues
end

-- Compute entropy bonus (encourages exploration)
-- policy: action probabilities [batch x nActions]
function AdvantageActorCritic:computeEntropy(policy)
   local entropy = 0
   local gradPolicy = torch.Tensor(policy:size()):zero()

   local batchSize = policy:size(1)
   local nActions = policy:size(2)

   for i = 1, batchSize do
      for a = 1, nActions do
         local p = math.max(policy[i][a], 1e-8)
         entropy = entropy - p * math.log(p)
         gradPolicy[i][a] = -(1 + math.log(p))
      end
   end

   return entropy / batchSize, gradPolicy:div(batchSize)
end

-- Compute total A2C loss and gradients
-- Returns: totalLoss, {policyGrad, valueGrad}
function AdvantageActorCritic:computeLoss(observations, actions, advantages, returns)
   -- Forward pass
   local batchSize = observations:size(1)
   local policies = torch.Tensor(batchSize, self.actor.output:size(2) or self.actor.output:nElement())
   local values = torch.Tensor(batchSize)

   for i = 1, batchSize do
      local output = self:forward(observations[i])
      policies[i]:copy(output[1]:nDimension() > 1 and output[1]:squeeze() or output[1])
      values[i] = output[2]:nDimension() > 0 and output[2]:squeeze()[1] or output[2]
   end

   -- Policy loss
   local policyLoss, policyGrad = self:computePolicyLoss(policies, actions, advantages)

   -- Value loss
   local valueLoss, valueGrad = self:computeValueLoss(values, returns)

   -- Entropy bonus
   local entropy, entropyGrad = self:computeEntropy(policies)

   -- Total loss: policy_loss + value_coef * value_loss - entropy_coef * entropy
   local totalLoss = policyLoss + self.valueLossCoef * valueLoss - self.entropyCoef * entropy

   -- Combined policy gradient (policy grad - entropy grad for maximizing entropy)
   local totalPolicyGrad = policyGrad:add(-self.entropyCoef, entropyGrad)

   -- Scale value gradient
   local totalValueGrad = valueGrad:mul(self.valueLossCoef)

   return totalLoss, {totalPolicyGrad, totalValueGrad}, {
      policyLoss = policyLoss,
      valueLoss = valueLoss,
      entropy = entropy
   }
end

-- Perform a training step using stored rollout data
function AdvantageActorCritic:trainStep(lastValue)
   local T = #self._observations
   if T == 0 then
      return 0
   end

   -- Compute advantages
   local advantages, returns = self:computeAdvantages(lastValue)

   -- Normalize advantages
   local advMean = advantages:mean()
   local advStd = advantages:std() + 1e-8
   advantages:add(-advMean):div(advStd)

   -- Stack observations
   local obsDim = self._observations[1]:size()
   local observations
   if obsDim:size() == 1 then
      observations = torch.Tensor(T, obsDim[1])
   else
      local dims = {T}
      for i = 1, obsDim:size() do
         dims[#dims + 1] = obsDim[i]
      end
      observations = torch.Tensor(torch.LongStorage(dims))
   end

   local actions = torch.LongTensor(T)

   for i = 1, T do
      observations[i]:copy(self._observations[i])
      actions[i] = self._actions[i]
   end

   -- Compute loss
   local loss, grads, metrics = self:computeLoss(observations, actions, advantages, returns)

   -- Clear rollout
   self:clearRollout()

   return loss, metrics
end

-- Select action from policy
function AdvantageActorCritic:selectAction(observation)
   local output = self:forward(observation)
   local policy = output[1]
   local value = output[2]

   -- Sample from policy
   local prob = policy:nDimension() > 1 and policy:squeeze() or policy
   local r = torch.uniform()
   local cumsum = 0
   local action = prob:size(1)

   for i = 1, prob:size(1) do
      cumsum = cumsum + prob[i]
      if r <= cumsum then
         action = i
         break
      end
   end

   local logProb = math.log(math.max(prob[action], 1e-8))
   local v = value:nDimension() > 0 and value:squeeze()[1] or value

   return action, v, logProb
end

function AdvantageActorCritic:__tostring__()
   local tab = '  '
   local line = '\n'
   local str = torch.type(self) .. string.format(
      '(gamma=%.3f, lambda=%.3f, entropyCoef=%.4f)',
      self.gamma, self.lambda, self.entropyCoef) .. ' {' .. line

   str = str .. tab .. '[actor]: ' .. tostring(self.actor):gsub(line, line .. tab) .. line
   str = str .. tab .. '[critic]: ' .. tostring(self.critic):gsub(line, line .. tab) .. line
   str = str .. '}'
   return str
end
