------------------------------------------------------------------------
--[[ ActorCritic ]]--
-- Container for Actor-Critic reinforcement learning.
-- Combines a policy network (actor) and a value network (critic).
--
-- The actor outputs action probabilities, the critic outputs state values.
-- Both networks share input (observations) and can share lower layers.
------------------------------------------------------------------------
local ActorCritic, parent = torch.class('nn.ActorCritic', 'nn.Container')

function ActorCritic:__init(actor, critic, sharedBase)
   parent.__init(self)
   self.actor = actor       -- policy network
   self.critic = critic     -- value network
   self.sharedBase = sharedBase  -- optional shared feature extractor

   self.modules = {}
   if sharedBase then
      table.insert(self.modules, sharedBase)
   end
   if actor then
      table.insert(self.modules, actor)
   end
   if critic then
      table.insert(self.modules, critic)
   end

   -- Output is a table {policy_output, value_output}
   self.output = {}
   self.gradInput = torch.Tensor()
end

-- Set actor network
function ActorCritic:setActor(actor)
   self.actor = actor
   self:_rebuildModules()
   return self
end

-- Set critic network
function ActorCritic:setCritic(critic)
   self.critic = critic
   self:_rebuildModules()
   return self
end

-- Set shared base network
function ActorCritic:setSharedBase(sharedBase)
   self.sharedBase = sharedBase
   self:_rebuildModules()
   return self
end

function ActorCritic:_rebuildModules()
   self.modules = {}
   if self.sharedBase then
      table.insert(self.modules, self.sharedBase)
   end
   if self.actor then
      table.insert(self.modules, self.actor)
   end
   if self.critic then
      table.insert(self.modules, self.critic)
   end
end

-- Forward pass
-- Returns {actorOutput, criticOutput}
function ActorCritic:updateOutput(input)
   local features = input

   -- Pass through shared base if present
   if self.sharedBase then
      features = self.sharedBase:updateOutput(input)
   end

   -- Actor forward
   local actorOutput = self.actor:updateOutput(features)

   -- Critic forward
   local criticOutput = self.critic:updateOutput(features)

   self.output = {actorOutput, criticOutput}
   return self.output
end

-- Backward pass
-- gradOutput should be {actorGrad, criticGrad}
function ActorCritic:updateGradInput(input, gradOutput)
   local actorGrad = gradOutput[1]
   local criticGrad = gradOutput[2]

   local features = input
   if self.sharedBase then
      features = self.sharedBase.output
   end

   -- Backward through actor
   local actorGradInput = self.actor:updateGradInput(features, actorGrad)

   -- Backward through critic
   local criticGradInput = self.critic:updateGradInput(features, criticGrad)

   -- Combine gradients
   if self.sharedBase then
      -- Sum gradients from actor and critic
      local combinedGrad = actorGradInput:clone():add(criticGradInput)
      self.gradInput = self.sharedBase:updateGradInput(input, combinedGrad)
   else
      self.gradInput = actorGradInput:clone():add(criticGradInput)
   end

   return self.gradInput
end

function ActorCritic:accGradParameters(input, gradOutput, scale)
   scale = scale or 1
   local actorGrad = gradOutput[1]
   local criticGrad = gradOutput[2]

   local features = input
   if self.sharedBase then
      features = self.sharedBase.output
   end

   -- Accumulate actor gradients
   self.actor:accGradParameters(features, actorGrad, scale)

   -- Accumulate critic gradients
   self.critic:accGradParameters(features, criticGrad, scale)

   -- Accumulate shared base gradients
   if self.sharedBase then
      local actorGradInput = self.actor.gradInput
      local criticGradInput = self.critic.gradInput
      local combinedGrad = actorGradInput:clone():add(criticGradInput)
      self.sharedBase:accGradParameters(input, combinedGrad, scale)
   end
end

-- Get actor output (policy)
function ActorCritic:getPolicy()
   return self.output[1]
end

-- Get critic output (value)
function ActorCritic:getValue()
   return self.output[2]
end

-- Forward only actor
function ActorCritic:forwardActor(input)
   local features = input
   if self.sharedBase then
      features = self.sharedBase:forward(input)
   end
   return self.actor:forward(features)
end

-- Forward only critic
function ActorCritic:forwardCritic(input)
   local features = input
   if self.sharedBase then
      features = self.sharedBase:forward(input)
   end
   return self.critic:forward(features)
end

function ActorCritic:__tostring__()
   local tab = '  '
   local line = '\n'
   local str = torch.type(self) .. ' {' .. line

   if self.sharedBase then
      str = str .. tab .. '[sharedBase]: ' .. tostring(self.sharedBase):gsub(line, line .. tab) .. line
   end
   if self.actor then
      str = str .. tab .. '[actor]: ' .. tostring(self.actor):gsub(line, line .. tab) .. line
   end
   if self.critic then
      str = str .. tab .. '[critic]: ' .. tostring(self.critic):gsub(line, line .. tab) .. line
   end

   str = str .. '}'
   return str
end
